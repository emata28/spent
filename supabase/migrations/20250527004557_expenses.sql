CREATE TABLE currencies (
    id SERIAL PRIMARY KEY,
    code VARCHAR(3) NOT NULL UNIQUE,
    name TEXT NOT NULL,
    symbol VARCHAR(5) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE expenses (
    id SERIAL,
    user_id UUID NOT NULL,
    amount NUMERIC NOT NULL,
    currency_id INTEGER NOT NULL,
    date DATE NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, user_id),
    FOREIGN KEY (currency_id) REFERENCES currencies(id)
);

CREATE TABLE expense_categories (
    expense_id INTEGER,
    user_id UUID NOT NULL,
    category_id INTEGER REFERENCES categories(id),
    PRIMARY KEY (expense_id, category_id),
    FOREIGN KEY (expense_id, user_id) REFERENCES expenses(id, user_id)
);
