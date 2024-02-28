from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from version import __version__

from database import Base
from main import app, get_db

SQLALCHEMY_DATABASE_URL = "sqlite://"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False,
                                   bind=engine)

Base.metadata.create_all(bind=engine)


def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)


def test_version():
    response = client.get("/version")
    assert response.status_code == 200
    assert response.json() == {"version": f"v{__version__}"}


def test_add_returns_integer():
    response = client.get("/add")
    data = response.json()
    assert response.status_code == 200
    assert isinstance(data["counter"], int)


def test_show_returns_integer():
    response = client.get("/show")
    assert response.status_code == 200
    assert isinstance(response.json()["number"], int)


def test_add():
    response = client.get("/add")
    print(response)
    assert response.status_code == 200
    r1 = response.json()

    response = client.get("/add")
    assert response.status_code == 200
    r2 = response.json()

    assert r1["counter"] + 1 == r2["counter"]
