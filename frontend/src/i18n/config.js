import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

const resources = {
  uk: {
    translation: {
      home: 'Головна',
      users: 'Користувачі',
      suppliers: 'Постачальники',
      clients: 'Клієнти',
      components: 'Компоненти',
      products: 'Товари',
      recipes: 'Рецепти',
      settings: 'Налаштування',
      logout: 'Вихід',
      login: 'Логін',
      password: 'Пароль',
      name: 'Ім\'я',
      email: 'Email',
      phone: 'Телефон',
      telegram: 'Telegram',
      add: 'Додати',
      edit: 'Редагувати',
      save: 'Зберегти',
      cancel: 'Скасувати',
      type: 'Тип',
      wholesale: 'Оптовий',
      retail1: 'Роздріб 1',
      retail2: 'Роздріб 2',
      price: 'Ціна',
      quantity: 'Кількість',
      basePrice: 'Базова ціна',
      markup: 'Наценка',
      weight: 'Вага'
    }
  },
  ru: {
    translation: {
      home: 'Главная',
      users: 'Пользователи',
      suppliers: 'Поставщики',
      clients: 'Клиенты',
      components: 'Компоненты',
      products: 'Товары',
      recipes: 'Рецепты',
      settings: 'Настройки',
      logout: 'Выход',
      login: 'Логин',
      password: 'Пароль',
      name: 'Имя',
      email: 'Email',
      phone: 'Телефон',
      telegram: 'Telegram',
      add: 'Добавить',
      edit: 'Редактировать',
      save: 'Сохранить',
      cancel: 'Отмена',
      type: 'Тип',
      wholesale: 'Оптовый',
      retail1: 'Розница 1',
      retail2: 'Розница 2',
      price: 'Цена',
      quantity: 'Количество',
      basePrice: 'Базовая цена',
      markup: 'Наценка',
      weight: 'Вес'
    }
  },
  en: {
    translation: {
      home: 'Home',
      users: 'Users',
      suppliers: 'Suppliers',
      clients: 'Clients',
      components: 'Components',
      products: 'Products',
      recipes: 'Recipes',
      settings: 'Settings',
      logout: 'Logout',
      login: 'Login',
      password: 'Password',
      name: 'Name',
      email: 'Email',
      phone: 'Phone',
      telegram: 'Telegram',
      add: 'Add',
      edit: 'Edit',
      save: 'Save',
      cancel: 'Cancel',
      type: 'Type',
      wholesale: 'Wholesale',
      retail1: 'Retail 1',
      retail2: 'Retail 2',
      price: 'Price',
      quantity: 'Quantity',
      basePrice: 'Base Price',
      markup: 'Markup',
      weight: 'Weight'
    }
  }
};

i18n.use(initReactI18next).init({
  resources,
  lng: 'uk',
  fallbackLng: 'en',
  interpolation: { escapeValue: false }
});

export default i18n;
