FROM ruby:3.1.4

WORKDIR /app

COPY . /app

RUN bundle

CMD ["bundle", "exec", "puma", "-C" ,"./puma.rb"]