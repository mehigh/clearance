module Clearance

  attr_accessible :email, :password, :password_confirmation
  attr_accessor :password, :password_confirmation

  validates_presence_of     :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_length_of       :password, :within => 3..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_uniqueness_of   :email
  
  before_save :encrypt_password

  def self.authenticate(email, password)
    user = find_by_email(email) # need to get the salt
    user && user.authenticated?(password) ? user : nil
  end

  def self.authenticate_via_auth_token(token)
    return nil if token.blank?
    find_by_auth_token(token)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end
  
  def encrypt(password)
    Digest::SHA1.hexdigest("--#{password}--")
  end
  
  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end
  
  def remember_me!
    remember_me_until 2.weeks.from_now.utc
  end
  
  def remember_me_until(time)
    self.update_attribute :remember_token_expires_at, time
    self.update_attribute :remember_token, encrypt("#{email}--#{remember_token_expires_at}")
  end
  
  def forget_me!
    self.update_attribute :remember_token_expires_at, nil
    self.update_attribute :remember_token, nil
  end

  protected
      
    def encrypt_password
      return if password.blank?
      self.crypted_password = encrypt(password)
    end

    def password_required?
      crypted_password.blank? || !password.blank?
    end

end