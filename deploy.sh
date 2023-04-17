#/bin/bash

do_bin_log()
{

docker compose -f docker-compose.mysql-repl-bin-log.yaml down
docker compose -f docker-compose.mysql-repl-bin-log.yaml up -d

until docker exec master mysqladmin -uroot -pmypass status
do
    echo "Waiting for master database connection..."
    sleep 4
done

echo "Import database"
docker exec -it master mysql -uroot -pmypass \
  -e "SOURCE /root/FinancialDB/ddl.sql;" \
  -e "SOURCE /root/FinancialDB/dml.sql;"

echo "Add user into master node for replicate"
docker exec -it master mysql -uroot -pmypass \
  -e "CREATE USER 'repl'@'%' IDENTIFIED BY 'slavepass';" \
  -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';" \
  -e "SHOW MASTER STATUS;"


echo "Set up slave node"
for N in 1 2
do
	#until docker compose exec slave-$N mysqladmin -uroot -pmypass status
	#do
	#    echo "Waiting for slave database connection..."
	#        sleep 4
	#done
	docker exec -it slave-$N mysql -uroot -pmypass \
		      -e "CHANGE MASTER TO MASTER_HOST='master', MASTER_USER='repl', \
		            MASTER_PASSWORD='slavepass', MASTER_LOG_FILE='mysql-bin-1.000003';"

	docker exec -it slave-$N mysql -uroot -pmypass -e "START SLAVE;"
done

echo "Check slave status"
for N in 1 2
do
	docker exec -it slave-$N mysql -uroot -pmypass -e "SHOW SLAVE STATUS\G"
done

echo "Deploying may completed successfully"

}

do_gtid()
{
	echo "Start of script..."
docker compose -f docker-compose.mysql-repl-gtid.yaml  down
docker compose -f docker-compose.mysql-repl-gtid.yaml  up -d

until docker exec master mysqladmin -uroot -pmypass status
do
    echo "Waiting for master database connection..."
    sleep 4
done

echo "Import database"
docker exec -it master mysql -uroot -pmypass \
  -e "SOURCE /root/FinancialDB/ddl.sql;" \
  -e "SOURCE /root/FinancialDB/dml.sql;"

echo "Add user into master node for replicate"
docker exec -it master mysql -uroot -pmypass \
  -e "CREATE USER 'repl'@'%' IDENTIFIED BY 'slavepass';" \
  -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';" \
  -e "SHOW MASTER STATUS;"


echo "Set up slave node"
for N in 1 2
do
	#until docker compose exec slave-$N mysqladmin -uroot -pmypass status
	#do
	#    echo "Waiting for slave database connection..."
	#        sleep 4
	#done
	docker exec -it slave-$N mysql -uroot -pmypass \
		      -e "CHANGE MASTER TO MASTER_HOST='master', MASTER_USER='repl', \
		            MASTER_PASSWORD='slavepass', MASTER_AUTO_POSITION = 1;"

	docker exec -it slave-$N mysql -uroot -pmypass -e "START SLAVE;"
done

echo "Check slave status"
for N in 1 2
do
	docker exec -it slave-$N mysql -uroot -pmypass -e "SHOW SLAVE STATUS\G"
done

echo "Deploying may completed successfully"
}

if [ "$1" == "bin-log" ]; then
	do_bin_log
elif [ "$1" == "gtid" ]; then
	do_gtid
else
	echo "Use $0 bin-log or $0 gtid"
fi

