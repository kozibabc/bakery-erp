import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function UsersPage() {
  const [users, setUsers] = useState([]);
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    axios.get('http://localhost:3000/api/users', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setUsers(res.data))
      .catch(console.error);
  }, [token]);

  return (
    <div className="card">
      <h2>{t('users')}</h2>
      <table>
        <thead><tr><th>{t('login')}</th><th>{t('name')}</th></tr></thead>
        <tbody>
          {users.map(u => <tr key={u.id}><td>{u.login}</td><td>{u.name}</td></tr>)}
        </tbody>
      </table>
    </div>
  );
}

export default UsersPage;
