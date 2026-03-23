import React from 'react';
import { BrowserRouter as Router, Route, Switch } from 'react-router-dom';
import LoginScreen from './screens/LoginScreen';
import SignupScreen from './screens/SignupScreen';

const App = () => {
    return (
        <Router>
            <Switch>
                <Route path="/login" component={LoginScreen} />
                <Route path="/signup" component={SignupScreen} />
                <Route path="/" exact>
                    <h1>Welcome to Supabase Auth App</h1>
                </Route>
            </Switch>
        </Router>
    );
};

export default App;