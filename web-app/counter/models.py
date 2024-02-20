from sqlalchemy import Column, Integer, DateTime
from sqlalchemy.sql import functions as func

from database import Base


class Counter(Base):
    __tablename__ = "counter"

    number = Column(Integer, primary_key=True, autoincrement=True)
    time_created = Column(DateTime(timezone=True), server_default=func.now())
