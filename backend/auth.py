import os
import jwt
from datetime import datetime, timedelta
from typing import Optional
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from firebase_admin import auth as firebase_auth
from dotenv import load_dotenv
from database import get_db
import models

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/firebase-login")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=60*24*7) # 1 week
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def resolve_user_from_token(token: str, db: Session):
    # Try Firebase Token first
    try:
        decoded_token = firebase_auth.verify_id_token(token)
        uid = decoded_token.get("uid")
        email = decoded_token.get("email")
        phone_number = decoded_token.get("phone_number")
        
        user = db.query(models.User).filter(
            (models.User.firebase_uid == uid) | 
            (models.User.email == email) | 
            (models.User.mobile_number == phone_number)
        ).first()

        if user and not user.firebase_uid:
            user.firebase_uid = uid
            db.commit()
            
        return user
    except Exception:
        pass

    # Try Custom Legacy JWT (Backward compatibility for Flutter App)
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        sub = payload.get("sub")
        
        user = db.query(models.User).filter(
            (models.User.mobile_number == sub) | 
            (models.User.email == sub)
        ).first()
        return user
    except Exception:
        pass

    return None

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    user = resolve_user_from_token(token, db)
    if not user or not user.is_active:
        raise credentials_exception
    return user

async def get_current_user_optional(request: Request, db: Session = Depends(get_db)):
    authorization: str = request.headers.get("Authorization")
    if not authorization:
        return None
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        return None
    token = parts[1]
    return resolve_user_from_token(token, db)

async def get_current_admin(current_user: models.User = Depends(get_current_user)):
    if current_user.role not in ["admin", "staff"]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")
    return str(current_user.id)

def log_admin_action(db: Session, admin_id: str, action: str, module: str, record_id: str, details: dict = {}):
    log = models.ActivityLog(
        admin_id=admin_id,
        action=action,
        module_name=module,
        record_id=str(record_id),
        details=details
    )
    db.add(log)
    db.commit()
