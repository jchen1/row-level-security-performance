seed-db:
	make run-schema && \
	make insert-sample-data

destroy-db:
	(docker-compose down || true) && \
	docker volume rm row-level-security-performance_pgdata && \
	rm -f pgdata && touch pgdata

run-db:
	docker-compose up -d && sleep 2

run-schema:
	psql -d test -h localhost -W postgres -w -f $(schema)/schema.sql

insert-sample-data:
	psql -d test -h localhost -W postgres -w -f $(schema)/sample-data.sql

bench:
	echo "Running benchmark for $(schema)..." && \
	psql -d test -h localhost -W postgres -w -f bench.sql

bench-schema:
	make destroy-db && \
	make run-db && \
	make seed-db && \
	make bench | tail -n +6 | tail -r | tail -n +4 | tail -r | tee $(schema)/explain-analyze.txt
