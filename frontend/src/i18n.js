import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

const resources = {
  uk: { translation: { login: 'Логін', password: 'Пароль', signIn: 'Увійти', logout: 'Вихід', products: 'Товари', users: 'Користувачі', clients: 'Клієнти', suppliers: 'Постачальники', name: 'Ім\'я', phone: 'Телефон', description: 'Опис', language: 'Мова', add: 'Додати', code: 'Код' } },
  ru: { translation: { login: 'Логин', password: 'Пароль', signIn: 'Войти', logout: 'Выход', products: 'Товары', users: 'Пользователи', clients: 'Клиенты', suppliers: 'Поставщики', name: 'Имя', phone: 'Телефон', description: 'Описание', language: 'Язык', add: 'Добавить', code: 'Код' } },
  en: { translation: { login: 'Login', password: 'Password', signIn: 'Sign In', logout: 'Logout', products: 'Products', users: 'Users', clients: 'Clients', suppliers: 'Suppliers', name: 'Name', phone: 'Phone', description: 'Description', language: 'Language', add: 'Add', code: 'Code' } }
};

i18n.use(initReactI18next).init({
  resources,
  lng: 'uk',
  fallbackLng: 'en',
  interpolation: { escapeValue: false }
});

export default i18n;
