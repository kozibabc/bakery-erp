import React from 'react';

function TelegramLink({ username }) {
  if (!username) return null;
  const cleanUsername = username.replace('@', '');
  return (
    <a href={`https://t.me/${cleanUsername}`} target="_blank" rel="noopener noreferrer" className="telegram-link">
      @{cleanUsername}
    </a>
  );
}

export default TelegramLink;
