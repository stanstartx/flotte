from waitress import serve
from core.wsgi import application  # adapte si ton projet a un autre nom

if __name__ == "__main__":
    serve(application, host="0.0.0.0", port=8000)
