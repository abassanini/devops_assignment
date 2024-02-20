from sqlalchemy.orm import Session

import models


def get_counter(db: Session):
    return db.query(models.Counter)\
        .order_by(models.Counter.number.desc())\
        .first()


def insert_counter(db: Session):
    new_counter = models.Counter()
    db.add(new_counter)
    db.commit()
    db.refresh(new_counter)
    return new_counter
