
docker exec -it $(docker ps | grep postgres | awk '{print $1}') sh

#в контейнере
psql -U airflow

select * from sample_table;
