# Sample database: https://github.com/luisiestrada/FinancialDB

#Create docker network
docker network create mysql-replicanet

#Master
docker run -d --name=master --net=mysql-replicanet --hostname=master -p 3308:3306 \
  -v $PWD/d0:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=mypass \
  mysql/mysql-server:5.7 \
  --server-id=1 \
  --log-bin='mysql-bin-1.log'
  
#Slave 1
docker run -d --name=slave1 --net=mysql-replicanet --hostname=slave1 -p 3309:3306 \
  -v $PWD/d1:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=mypass \
  mysql/mysql-server:5.7 \
  --server-id=2

#Slave 2
docker run -d --name=slave2 --net=mysql-replicanet --hostname=slave2 -p 3310:3306 \
  -v $PWD/d2:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=mypass \
  mysql/mysql-server:5.7 \
  --server-id=3
  
#Set up user for relicate
docker exec -it master mysql -uroot -pmypass \
  -e "CREATE USER 'repl'@'%' IDENTIFIED BY 'slavepass';" \
  -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';" \
  -e "SHOW MASTER STATUS;"
  
#Set up slave node
for N in 1 2
  do docker exec -it slave$N mysql -uroot -pmypass \
    -e "CHANGE MASTER TO MASTER_HOST='master', MASTER_USER='repl', \
      MASTER_PASSWORD='slavepass', MASTER_LOG_FILE='mysql-bin-1.000003';"

  docker exec -it slave$N mysql -uroot -pmypass -e "START SLAVE;"
done

#Check slave status
docker exec -it slave1 mysql -uroot -pmypass -e "SHOW SLAVE STATUS\G"
docker exec -it slave2 mysql -uroot -pmypass -e "SHOW SLAVE STATUS\G"

#Test
docker exec -it master mysql -uroot -pmypass -e "CREATE DATABASE TEST; SHOW DATABASES;"
for N in 1 2
  do docker exec -it slave$N mysql -uroot -pmypass \
  -e "SHOW VARIABLES WHERE Variable_name = 'hostname';" \
  -e "SHOW DATABASES;"
done





## For GTID replication
#Set up user for relicate
docker exec -it master mysql -uroot -pmypass \
  -e "CREATE USER 'repl'@'%' IDENTIFIED BY 'slavepass';" \
  -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';" \
  -e "SHOW MASTER STATUS;"
  
#Set up slave node
for N in 1 2
  do docker exec -it slave$N mysql -uroot -pmypass \
    -e "CHANGE MASTER TO MASTER_HOST='master', MASTER_USER='repl', \
      MASTER_PASSWORD='slavepass', MASTER_AUTO_POSITION = 1;"

  docker exec -it slave$N mysql -uroot -pmypass -e "START SLAVE;"
done