# AIM Patron

Alma requires a regular load of users from a student information system (SIS).
For Michigan that SIS is ActiveDirectory/LDAP. This codebase transforms users
from Umich's ActiveDirectory/LDAP system into users that Alma can use. 

## Developer Setup

Clone the Repository

```
git clone git@github.com:mlibrary/aim-patron.git
cd aim-patron
```

run the init script

```
./init.sh
```

edit .env with actual environment variables; ask a developer if you need them

To run the tests:
```
docker-compose run --rm app bundle exec rspec
```

## Run the scripts locally

To run the aim-patron CLI locally do:

```
docker-compose run --rm app patron help
```
