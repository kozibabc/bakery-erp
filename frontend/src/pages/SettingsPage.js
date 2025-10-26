import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

function SettingsPage() {
  const [settings, setSettings] = useState({ wholesaleMarkup: 10, retail1Markup: 40, retail2Markup: 70 });
  const { t } = useTranslation();
  const token = localStorage.getItem('token');

  useEffect(() => {
    axios.get('http://localhost:3000/api/settings', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setSettings(res.data));
  }, []);

  const handleSave = () => {
    axios.put('http://localhost:3000/api/settings', settings, { headers: { Authorization: `Bearer ${token}` } })
      .then(() => alert('Збережено!'));
  };

  return (
    <div className="card">
      <h2>{t('settings')}</h2>
      <div className="form-group">
        <label>{t('wholesale')} {t('markup')} (%)</label>
        <input value={settings.wholesaleMarkup} onChange={e => setSettings({...settings, wholesaleMarkup: e.target.value})} type="number" />
      </div>
      <div className="form-group">
        <label>{t('retail1')} {t('markup')} (%)</label>
        <input value={settings.retail1Markup} onChange={e => setSettings({...settings, retail1Markup: e.target.value})} type="number" />
      </div>
      <div className="form-group">
        <label>{t('retail2')} {t('markup')} (%)</label>
        <input value={settings.retail2Markup} onChange={e => setSettings({...settings, retail2Markup: e.target.value})} type="number" />
      </div>
      <button className="btn btn-primary" onClick={handleSave}>{t('save')}</button>
    </div>
  );
}

export default SettingsPage;
