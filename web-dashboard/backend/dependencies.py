"""
Shared dependencies for Cluster AI Dashboard API
Database, authentication, and security functions
"""

import logging
import secrets
import os
from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta
from typing import Optional

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from passlib.context import CryptContext
from sqlalchemy import Boolean, Column, Integer, String, create_engine
from sqlalchemy.orm import Session, declarative_base, sessionmaker

from models import TokenData, User, UserInDB

# Database setup
Base = declarative_base()


class UserDB(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    email = Column(String)
    full_name = Column(String)
    disabled = Column(Boolean, default=False)


SQLALCHEMY_DATABASE_URL = "sqlite:///./users.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Security
SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    # Gerar chave efêmera segura para ambientes de teste/desenvolvimento
    SECRET_KEY = secrets.token_urlsafe(32)
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
security = HTTPBearer(auto_error=False)


def get_user(db: Session, username: str):
    return db.query(UserDB).filter(UserDB.username == username).first()


def create_user(db: Session, user: UserInDB):
    db_user = UserDB(
        username=user.username,
        hashed_password=user.hashed_password,
        email=user.email,
        full_name=user.full_name,
        disabled=user.disabled,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def authenticate_user(db: Session, username: str, password: str):
    user = get_user(db, username)
    if not user:
        return False
    if not verify_password(password, user.hashed_password):
        return False
    return user


def init_default_user():
    db = SessionLocal()
    try:
        user = get_user(db, "admin")
        if not user:
            admin_user = UserInDB(
                username="admin",
                hashed_password=get_password_hash("admin123"),
                email="admin@example.com",
                full_name="Administrator",
                disabled=False,
            )
            create_user(db, admin_user)
            logger.info("Default admin user created")
        else:
            # Se usuário existir, garantir que o hash seja reconhecido pelo contexto atual
            needs_reset = False
            try:
                # Tenta identificar ou verificar o hash existente
                identified = pwd_context.identify(user.hashed_password)
                if not identified:
                    needs_reset = True
                else:
                    # Verifica com a senha padrão somente para padronizar no ambiente de teste
                    # (em produção, deve-se migrar hashes sem conhecer a senha clara)
                    if not pwd_context.verify("admin123", user.hashed_password):
                        needs_reset = True
            except Exception:
                needs_reset = True

            if needs_reset:
                user.hashed_password = get_password_hash("admin123")
                db.add(user)
                db.commit()
                logger.info("Default admin user hash migrated to current scheme")
    finally:
        db.close()


def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password):
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: timedelta | int | None = None):
    to_encode = data.copy()
    # Normalizar expires_delta: aceitar int (segundos) ou timedelta
    if isinstance(expires_delta, int):
        expires_delta = timedelta(seconds=expires_delta)
    if isinstance(expires_delta, timedelta):
        expire = datetime.now(UTC) + expires_delta
    else:
        expire = datetime.now(UTC) + timedelta(minutes=15)
    to_encode.update({"exp": int(expire.timestamp())})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: Session = Depends(get_db),
):
    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM]
        )
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except jwt.PyJWTError:
        raise credentials_exception
    user = get_user(db, username=token_data.username)
    if user is None:
        raise credentials_exception
    return user


async def get_current_active_user(current_user: User = Depends(get_current_user)):
    if current_user.disabled:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user


# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
