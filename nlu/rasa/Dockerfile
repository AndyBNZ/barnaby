FROM rasa/rasa:3.6.4

WORKDIR /app

COPY . /app

RUN rasa train nlu

EXPOSE 5005

CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "5005"]