require "redis"
require "sinatra"
require "digest/sha1"
require "json"

class GitCoin < Sinatra::Base
  TARGET_KEY = "gitcoin:current_target"
  GITCOINS_SET_KEY = "gitcoins:by_owner"

  configure do
    if ENV["REDISTOGO_URL"] #heroku
      uri = URI.parse(ENV["REDISTOGO_URL"])
      REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    else
      REDIS = Redis.new
    end

    REDIS.set(TARGET_KEY, Digest::SHA1.hexdigest("pizza")) unless REDIS.get(TARGET_KEY)
  end

  get "/target" do
    current_target
  end

  get "/gitcoins" do
    #render current gitcoins
    "hi"
  end

  post "/hash" do
    content_type :json
    if coin = new_target?(params[:message], params[:owner])
      {:success => true, :gitcoin_assigned => coin, :new_target => current_target}.to_json
    else
      {:success => false, :gitcoin_assigned => false, :new_target => current_target}.to_json
    end
  end

  def new_target?(message, owner)
    digest = Digest::SHA1.hexdigest(message)
    if digest.hex < current_target.hex
      assign_gitcoin(owner, digest)
      set_target(digest)
    else
      false
    end
  end

  def set_target(digest)
    REDIS.set(TARGET_KEY, digest)
  end

  def assign_gitcoin(owner, digest)
    REDIS.sadd(GITCOINS_SET_KEY, "#{owner}:#{digest}")
  end

  def current_target
    REDIS.get(TARGET_KEY)
  end
end