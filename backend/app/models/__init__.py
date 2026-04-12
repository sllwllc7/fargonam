"""
Barcha modellarni shu yerda import qilamiz —
Alembic va `Base.metadata` ularni topishi uchun.
"""
from app.models.announcement import Announcement
from app.models.banner import Banner
from app.models.cart import CartItem
from app.models.favorite import Favorite
from app.models.fcm_token import FcmToken
from app.models.message import Message
from app.models.news import NewsPost
from app.models.news_interaction import NewsComment, NewsLike
from app.models.notification import Notification
from app.models.product_image import ProductImage
from app.models.review import Review
from app.models.ride_rating import RideRating
from app.models.saved_address import SavedAddress
from app.models.ride import DriverProfile, Ride, RideStatus
from app.models.category import Category
from app.models.order import Order, OrderItem, OrderStatus
from app.models.product import Product
from app.models.shop import Shop
from app.models.user import User, UserRole

__all__ = [
    "Announcement",
    "Banner",
    "DriverProfile",
    "Favorite",
    "FcmToken",
    "Message",
    "NewsComment",
    "NewsLike",
    "NewsPost",
    "Notification",
    "ProductImage",
    "Review",
    "RideRating",
    "SavedAddress",
    "Ride",
    "RideStatus",
    "User",
    "UserRole",
    "Shop",
    "Category",
    "Product",
    "CartItem",
    "Order",
    "OrderItem",
    "OrderStatus",
]
