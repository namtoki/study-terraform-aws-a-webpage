FROM ruby:3.3-slim

# 依存パッケージ
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      nodejs \
      curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Gem のインストール（レイヤーキャッシュを活かすため先に COPY）
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# アプリケーションコードをコピー
COPY . .

# アセットのプリコンパイル
RUN bundle exec rails assets:precompile RAILS_ENV=production SECRET_KEY_BASE=dummy

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
