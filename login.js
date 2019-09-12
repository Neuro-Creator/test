'use strict';
import React           from 'react';
import LoginContainer  from '../containers/loginContainer'
import { UserStatus }  from './userStatus';
import { cy, genKey }  from './session.js';
import { componentRender,
         componentClear }  from './basestore';
import Linkster            from './linkster';
import ProtoContainer      from '../containers/protoContainer';

const { USER_LOGGED_IN, USER_LOGGED_OUT, USER_WRONG } = UserStatus;

const e = React.createElement;

class Login extends React.Component {
  constructor(props) {
    super(props);
    this.unameInput   = React.createRef();
    this.pwdInput     = React.createRef();
    this.handleSubmit = this.handleSubmit.bind(this);
    this.handleLogout = this.handleLogout.bind(this);
  }


  handleLogout(event) {
    base.attributes['cfg'].value = cy(32);
    this.props.logoutUser();
  }


  handleSubmit(event) {
    let base  = document.getElementById('base');
    let key   = base.attributes['cfg'].value;
    let uname = this.unameInput.current.value;
    let pwd   = this.pwdInput.current.value;
    let content = { uname,
                    pwd: `${cy(15)}`, 
                    sid:   `${key}-${genKey(key, pwd)}-${cy(24)}` };
    base.attributes['cfg'].value = 'none';
    sessionStorage.setItem('key', key);
    console.log('handleSubmit: ', content);
    this.props.submitUser(content);
    console.log('handleSubmit: done');
  }


  render() {
    if (this.props.userStatus == USER_LOGGED_IN) {
        componentRender(Linkster,  'xyz');
        componentRender(ProtoContainer, 'cnv');
        return e('div', {style: {width: '80px', margin: '0 auto'}},
                e('button', {onClick: this.handleLogout}, 'Logout'));
    }

    if (this.props.userStatus == USER_LOGGED_OUT) {
        return e('div', {style: {width: '300px', margin: '0 auto'}},
              e('input', {type:    'text',
                          style: {display: 'block', width: '300px'},
                          ref:      this.unameInput}, null),
              e('input', {type:    'password',
                          style: {display: 'block', width: '300px'},
                          ref:      this.pwdInput}, null),
              e('button', {onClick: this.handleSubmit}, 'Login'));
    }
  }
}

export default Login;
