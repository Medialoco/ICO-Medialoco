import Navbar from 'react-bootstrap/Navbar';

import logo from '../logo.png';

const Navigation = () => {
    return (
        <Navbar className='my-3'>
            <img
                alt="logo"
                src={logo}
                width="40"
                height="40"
                className="d-inline-block align-top mx-3"
            />
            <Navbar.Brand href="#">DApp ICO Crowdsale</Navbar.Brand>
        </Navbar>
    );
}

export default Navigation;