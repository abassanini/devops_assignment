import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool


my_connect_args = {}
my_poolclass = None
SQLALCHEMY_DATABASE_URL = os.environ.get("SQLALCHEMY_DATABASE_URL")
if SQLALCHEMY_DATABASE_URL is None:
    print("No SQLALCHEMY_DATABASE_URL provided.  Using Sqlite in memory mode")
    SQLALCHEMY_DATABASE_URL = "sqlite://"
    my_connect_args = {"check_same_thread": False}
    my_poolclass = StaticPool


engine = create_engine(SQLALCHEMY_DATABASE_URL,
                       connect_args=my_connect_args,
                       poolclass=my_poolclass)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
