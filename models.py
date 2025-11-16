from sqlalchemy import create_engine, Column, Integer, String, DateTime, Numeric, ForeignKey, Index
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, sessionmaker
from datetime import datetime
import os

Base = declarative_base()


class BusStop(Base):
    __tablename__ = 'bus_stops'

    id = Column(Integer, primary_key=True)
    busstop_id = Column(Integer, nullable=False, unique=True, index=True)
    street1 = Column(String, nullable=False)
    street2 = Column(String, nullable=False)
    street1_id = Column(Integer)
    street2_id = Column(Integer)
    latitude = Column(Numeric(10, 8), nullable=False)
    longitude = Column(Numeric(11, 8), nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    bus_passages = relationship("BusPassage", back_populates="bus_stop", cascade="all, delete-orphan")

    __table_args__ = (
        Index('index_bus_stops_on_latitude_and_longitude', 'latitude', 'longitude'),
    )

    @classmethod
    def find_or_create_from_api(cls, session, data):
        """Encuentra o crea una parada a partir de datos de la API"""
        busstop_id = data.get("busstopId")
        stop = session.query(cls).filter_by(busstop_id=busstop_id).first()
        
        if not stop:
            coordinates = data.get("location", {}).get("coordinates", [])
            stop = cls(
                busstop_id=busstop_id,
                street1=data.get("street1"),
                street2=data.get("street2"),
                street1_id=data.get("street1Id"),
                street2_id=data.get("street2Id"),
                latitude=coordinates[1] if len(coordinates) > 1 else None,
                longitude=coordinates[0] if len(coordinates) > 0 else None
            )
            session.add(stop)
            session.commit()
        
        return stop

    def __repr__(self):
        return f"<BusStop(id={self.id}, busstop_id={self.busstop_id}, {self.street1} y {self.street2})>"


class BusPassage(Base):
    __tablename__ = 'bus_passages'

    id = Column(Integer, primary_key=True)
    bus_stop_id = Column(Integer, ForeignKey('bus_stops.id'), nullable=False, index=True)
    line = Column(String, nullable=False, index=True)
    destination = Column(String)
    bus_code = Column(String)
    bus_latitude = Column(Numeric(10, 8))
    bus_longitude = Column(Numeric(11, 8))
    detected_at = Column(DateTime, nullable=False, index=True)
    eta_minutes = Column(Integer)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    bus_stop = relationship("BusStop", back_populates="bus_passages")

    __table_args__ = (
        Index('index_bus_passages_on_bus_stop_id_and_detected_at', 'bus_stop_id', 'detected_at'),
    )

    @classmethod
    def create_from_bus_data(cls, session, bus_stop, bus_data, detected_at=None):
        """Crea un registro de pasada de bondi a partir de datos de la API"""
        if detected_at is None:
            detected_at = datetime.utcnow()
        
        coordinates = bus_data.get("location", {}).get("coordinates", [])
        eta = bus_data.get("eta", {})
        
        passage = cls(
            bus_stop_id=bus_stop.id,
            line=bus_data.get("line"),
            destination=bus_data.get("destination"),
            bus_code=bus_data.get("busCode"),
            bus_latitude=coordinates[1] if len(coordinates) > 1 else None,
            bus_longitude=coordinates[0] if len(coordinates) > 0 else None,
            detected_at=detected_at,
            eta_minutes=eta.get("minutes") if isinstance(eta, dict) else None
        )
        session.add(passage)
        session.commit()
        
        return passage

    def __repr__(self):
        return f"<BusPassage(id={self.id}, line={self.line}, detected_at={self.detected_at})>"


def get_db_engine(database_url=None):
    """Crea el engine de SQLAlchemy para conectarse a la base de datos"""
    if database_url is None:
        # Usar la misma configuración que Rails en development
        database_url = os.getenv("DATABASE_URL", "postgresql://localhost/bus_tracker_development")
    
    engine = create_engine(database_url, echo=False)
    return engine


def get_session(engine=None):
    """Crea una sesión de SQLAlchemy"""
    if engine is None:
        engine = get_db_engine()
    
    Session = sessionmaker(bind=engine)
    return Session()
