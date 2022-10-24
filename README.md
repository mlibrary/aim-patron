# LDAP to Alma Patrons

Alma requires a regular load of users from a student information system (SIS). For Umich that SIS is ActiveDirectory/LDAP. This codebase transforms users from Umich's ActiveDirectory/LDAP system into users that Alma can use. 

## Developer Setup

Clone the Repository

```
git clone git@github.com:mlibrary/ldap-to-alma-patrons.git
cd ldap-to-alma-patrons
```

copy .env-example to .env

```
cp .env-example .env
```

edit .env with actual environment variables; ask a developer if you need them

build container
```
docker-compose build
```

bundle install
```
docker-compose run --rm web bundle install
```

To run the tests:
```
docker-compose run --rm web bundle exec rspec
```
