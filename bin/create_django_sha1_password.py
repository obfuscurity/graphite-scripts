import hashlib
from django.utils.encoding import smart_str
from django.contrib import auth

UNUSABLE_PASSWORD = '!' # This will never be a valid hash

def get_random_string(length=12, allowed_chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'):
  import random
  try:
    random = random.SystemRandom()
  except NotImplementedError:
    pass
  return ''.join([random.choice(allowed_chars) for i in range(length)])

def get_hexdigest(algorithm, salt, raw_password):
  """
  Returns a string of the hexdigest of the given plaintext password and salt
  using the given algorithm ('md5', 'sha1' or 'crypt').
  """
  raw_password, salt = smart_str(raw_password), smart_str(salt)
  if algorithm == 'crypt':
    try:
      import crypt
    except ImportError:
      raise ValueError('"crypt" password algorithm not supported in this environment')
    return crypt.crypt(raw_password, salt)

  if algorithm == 'md5':
    return hashlib.md5(salt + raw_password).hexdigest()
  elif algorithm == 'sha1':
    return hashlib.sha1(salt + raw_password).hexdigest()
  raise ValueError("Got unknown password algorithm type in password.")

def check_password(raw_password, enc_password):
  """
  Returns a boolean of whether the raw_password was correct. Handles
  encryption formats behind the scenes.
  """
  algo, salt, hsh = enc_password.split('$')
  return hsh == get_hexdigest(algo, salt, raw_password)

def make_password(algo, raw_password):
  """
  Produce a new password string in this format: algorithm$salt$hash
  """
  if raw_password is None:
    return UNUSABLE_PASSWORD
  salt = get_random_string()
  hsh = get_hexdigest(algo, salt, raw_password)
  return '%s$%s$%s' % (algo, salt, hsh)

print make_password('sha1', 'foobar');
