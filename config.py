import datetime
import os
basedir = os.path.abspath(os.path.dirname(__file__))

class Config:
	# secret key
	SECRET_KEY = os.environ.get('SECRET_KEY') or 'x8qv*$gsb4^9_*-2dkl85@dm@nbti@ksm2of4!j&rxp4h-n0ui'
	
    # jwt
    JWT_SECRET_KEY = os.environ.get('SECRET_KEY') or 'iiq+x%^o#f90*#(_p%61w+%+bfd&g^gtt&p=f+gh0@bjlv1-(u'
    JWT_ACCESS_TOKEN_LIFETIME = os.environ.get('SECRET_KEY') or 3600
    JWT_ACCESS_TOKEN_EXPIRES = datetime.timedelta(seconds=JWT_ACCESS_TOKEN_LIFETIME)
    JWT_BLACKLIST_ENABLED = True
    JWT_BLACKLIST_TOKEN_CHECKS = ['access', 'refresh']
    
    # mail
    MAIL_SERVER = os.environ.get('SECRET_KEY') or 'smtp.gmail.com'
    MAIL_PORT = os.environ.get('SECRET_KEY') or 465
    MAIL_USE_SSL = True
    MAIL_USERNAME = os.environ.get('SECRET_KEY') or 'noreply@legaltara.com'
    MAIL_PASSWORD = os.environ.get('SECRET_KEY') or 'Waltham11'
    MAIL_DEFAULT_SENDER = os.environ.get('SECRET_KEY') or 'LegalTara <norelpy@legaltara.com>'
    
    # paypal
    PAYPAL_MODE = os.environ.get('SECRET_KEY') or 'sandbox'
    PAYPAL_CLIENT_ID = os.environ.get('SECRET_KEY') or 'AWWdLFCAqHT-ccP4BE5uojEPIXpAJr_4HgFb97Y_-o8vGOKDB4x8VNCSb8QkpwEhIcJIcIvXo4IIFQDp'
    PAYPAL_CLIENT_SECRET = os.environ.get('SECRET_KEY') or 'EDsK98Q6uIsfvIQYyZ6TyQvuRjtA-QnB-x7TpuQulR4csjISOayGXsgrj1aNfnsKyPIIeuIHacj3BMlz'
    
    # google oauth2
    GOOGLE_OAUTH2 = os.environ.get('SECRET_KEY') or 'xxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com'
	
    # database
    POSTGRES = {
        'user': 'xxxxx',
        'pw': 'xxxxx',
        'db': 'xxxx',
        'host': 'xxx.xxx.xxx.xxx',
        'port': '5432',
    }
    
    SQLALCHEMY_DATABASE_URI = 'postgresql://%(user)s:%(pw)s@%(host)s:%(port)s/%(db)s' % POSTGRES
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    @staticmethod
    def init_app(app):
		pass


class ProductionConfig(Config):
    DEBUG = False
    TESTING = False
    SQLALCHEMY_DATABASE_URI = 'postgresql://%(user)s:%(pw)s@%(host)s:%(port)s/%(db)s' % POSTGRES

    pass


class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = 'postgresql://%(user)s:%(pw)s@%(host)s:%(port)s/%(db)s' % POSTGRES


class TestingConfig(Config):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'postgresql://%(user)s:%(pw)s@%(host)s:%(port)s/%(db)s' % POSTGRES

config = {
	'development': DevelopmentConfig,
	'testing': TestingConfig,
	'production': ProductionConfig
	'default': DevelopmentConfig
}
