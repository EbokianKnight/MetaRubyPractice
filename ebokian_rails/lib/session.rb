require 'json'
require 'byebug'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    if req.cookies["_rails_lite_app"]
      @rails_lite = JSON.parse(req.cookies["_rails_lite_app"])
    else
      @rails_lite = {}
    end
  end

  def [](key)
    @rails_lite[key]
  end

  def []=(key, val)
    @rails_lite[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    cookie = @rails_lite.to_json
    res.set_cookie("_rails_lite_app", path: "/", value: cookie)
  end
end
