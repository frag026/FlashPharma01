# Supabase Auth App

This project is a simple authentication application built using React and Supabase. It provides users with the ability to sign up and log in using a user-friendly interface.

## Features

- User signup and login functionality
- Reusable authentication form component
- TypeScript support for type safety
- Custom hooks for managing authentication logic

## Project Structure

```
supabase-auth-app
├── src
│   ├── app.tsx                # Main entry point of the application
│   ├── supabase
│   │   └── client.ts          # Configured Supabase client instance
│   ├── screens
│   │   ├── LoginScreen.tsx    # Login screen component
│   │   └── SignupScreen.tsx   # Signup screen component
│   ├── components
│   │   └── AuthForm.tsx       # Reusable authentication form component
│   ├── hooks
│   │   └── useAuth.ts         # Custom hook for authentication logic
│   └── types
│       └── index.ts           # TypeScript interfaces for user data
├── package.json                # npm configuration file
├── tsconfig.json              # TypeScript configuration file
└── README.md                  # Project documentation
```

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/supabase-auth-app.git
   ```

2. Navigate to the project directory:
   ```
   cd supabase-auth-app
   ```

3. Install the dependencies:
   ```
   npm install
   ```

## Usage

1. Set up your Supabase project and obtain the API keys.
2. Configure the Supabase client in `src/supabase/client.ts` with your Supabase URL and public API key.
3. Start the development server:
   ```
   npm start
   ```

4. Open your browser and navigate to `http://localhost:3000` to view the application.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.