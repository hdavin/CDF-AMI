function key = te_hash(value)
% Content-based cache keys, independent of figure options and loop order.
digest = java.security.MessageDigest.getInstance('SHA-256');
digest.update(unicode2native(jsonencode(value),'UTF-8'));
bytes = typecast(digest.digest(),'uint8');
key = lower(reshape(dec2hex(bytes,2).',1,[]));
end
