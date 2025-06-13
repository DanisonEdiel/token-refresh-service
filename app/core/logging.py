import sys
import logging
from pathlib import Path
from loguru import logger
from pydantic import BaseModel

from app.core.config import settings


class LoggingConfig(BaseModel):
    """Logging configuration"""
    
    LOGGER_NAME: str = "token_refresh_service"
    LOG_FORMAT: str = "<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - <level>{message}</level>"
    LOG_LEVEL: str = settings.LOG_LEVEL


class InterceptHandler(logging.Handler):
    """
    Default handler from examples in loguru documentation.
    See https://loguru.readthedocs.io/en/stable/overview.html#entirely-compatible-with-standard-logging
    """

    def emit(self, record: logging.LogRecord):
        # Get corresponding Loguru level if it exists
        try:
            level = logger.level(record.levelname).name
        except ValueError:
            level = record.levelno

        # Find caller from where originated the logged message
        frame, depth = logging.currentframe(), 2
        while frame.f_code.co_filename == logging.__file__:
            frame = frame.f_back
            depth += 1

        logger.opt(depth=depth, exception=record.exc_info).log(
            level, record.getMessage()
        )


def setup_logging():
    """Configure logging"""
    
    config = LoggingConfig()
    
    # Remove all handlers from root logger
    logging.root.handlers = [InterceptHandler()]
    logging.root.setLevel(config.LOG_LEVEL)
    
    # Remove every other logger's handlers and propagate to root logger
    for name in logging.root.manager.loggerDict.keys():
        logging.getLogger(name).handlers = []
        logging.getLogger(name).propagate = True
    
    # Configure loguru
    logger.configure(
        handlers=[
            {
                "sink": sys.stdout,
                "format": config.LOG_FORMAT,
                "level": config.LOG_LEVEL,
                "colorize": True,
            }
        ]
    )
    
    return logger
