FROM alpine:latest

RUN apk update && apk add postgresql postgresql-client python3-dev musl-dev gcc postgresql-dev

RUN python3 -m ensurepip && pip3 install --upgrade pip

WORKDIR /pythonProject

COPY requirements.txt .

RUN pip install -r requirements.txt

RUN mkdir /pythonProject/static

COPY . .
RUN python manage.py collectstatic --noinput


RUN apk add nginx
COPY ./nginx.conf /etc/nginx/http.d/default.conf


RUN mkdir -p /run/postgresql && chown -R postgres:postgres /run/postgresql
RUN mkdir /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql/data

USER postgres
ENV POSTGRES_USER=postgres
ENV POSTGRES_HOST=0.0.0.0
ENV POSTGRES_PORT=5432
ENV POSTGRES_DB=postgres
ENV POSTGRES_PASSWORD=postgres

RUN initdb -D /var/lib/postgresql/data && \
    pg_ctl start -D /var/lib/postgresql/data && \
    echo "ALTER USER postgres PASSWORD 'postgres';" && \
    pg_ctl stop -D /var/lib/postgresql/data


USER root
CMD nginx && su postgres -c 'pg_ctl start -D /var/lib/postgresql/data' && \
   python manage.py migrate && python manage.py createadminuser && \
   gunicorn -b 0.0.0.0:8000 djangoProject.wsgi:application

EXPOSE 80
EXPOSE 5432
EXPOSE 8000