class User < ActiveRecord::Base
  attr_accessible :api_key, :ln, :sn
end
