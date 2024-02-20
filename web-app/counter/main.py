from fastapi import Depends, FastAPI
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from prometheus_fastapi_instrumentator import Instrumentator

import crud
import models
from database import SessionLocal, engine
from version import __version__

models.Base.metadata.create_all(bind=engine)


# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


app = FastAPI()


@app.get("/add")
def add(db: Session = Depends(get_db)):
    counter = crud.insert_counter(db)
    return {"counter": counter.number}


@app.get("/show")
def show(db: Session = Depends(get_db)):
    return crud.get_counter(db)


@app.get("/version")
def version():
    return {"version": f"v{__version__}"}


Instrumentator().instrument(app).expose(app)
app.mount("/", StaticFiles(directory="static", html=True), name="static")
