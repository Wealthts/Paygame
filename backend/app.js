const express = require('express');
const cors = require('cors');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const con = require('./db_config');

const JWT_KEY = 'thisistheend';
const app = express();
app.use(cors());
app.use(express.json());

// hash password
app.get('/api/password/:raw', (req, res) => {
    const hash = argon2.hashSync(req.params.raw);
    console.log(hash.length);
    res.send(hash);
});

// login
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    const sql = "SELECT * FROM users WHERE username=?";
    con.query(sql, [username], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        // username exists?
        if (result.length != 1) {
            return res.status(401).send('Wrong username');
        }
        // verify password
        const hash = result[0].password;
        const same = argon2.verifySync(hash, password);
        if (!same) {
            return res.status(401).send('Wrong password');
        }
        // correct login
        // create token (JWT)
        const payload = { id: result[0].id, username: result[0].username, role: result[0].role }; //JSObject ไม่ต้องใส่ '' ก็ได้
        const token = jwt.sign(payload, JWT_KEY, { expiresIn: '1d' });
        res.send(token);
    })
});

// get all task
app.get('/api/todo', (req, res) => {
    // get JWT (header)
    // "urjujknsfds" pure token
    // "Bearer urjujknsfds" bearer token
    const header = req.headers['authorization'];
    const token = header && header.split(' ')[1]; //(' ') คืือระหว่าง Bearer กับ urjujkns，[1] คือ urjujknsfds


    let jwt_payload = " ";
    // check JWT, extract payload
    jwt.verify(token, JWT_KEY, (err, payload) => {
        if (err) {
            // wrong jwt or expired jwt
            return res.status(403).send('Unauthorized');
        }
        // console.log(payload);
        jwt_payload = payload;
    });
    
    const sql = "SELECT * FROM todo WHERE user_id=?";
    con.query(sql, [jwt_payload.id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        res.json(result);
    })
});

app.patch('/api/todo/:id', (req, res) => {
    const id = req.params.id;
    const { title, complete, favorite } = req.body;

    // Keep the title update and also allow status updates.
    let sql = "UPDATE todo SET title = ? WHERE id = ?";
    let value = title;

    if (complete !== undefined) {
        sql = "UPDATE todo SET complete = ? WHERE id = ?";
        value = complete;
    } else if (favorite !== undefined) {
        sql = "UPDATE todo SET favorite = ? WHERE id = ?";
        value = favorite;
    } else if (title === undefined) {
        return res.status(400).send('No task field to update');
    }

    con.query(sql, [value, id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }
        if (result.affectedRows !== 1) {
            console.error('Updated row is not 1');
            return res.status(404).send('Task not found');
        }
        res.send('Updated');
    });
});

// Add task
app.post('/api/todo', (req, res) => {
    const { title, deadline, complete, favorite } = req.body;
    const sql = `
        INSERT INTO todo (title, deadline, complete, favorite)
        VALUES (?, ?, ?, ?)
    `;

    con.query(
        sql,
        [title, deadline, complete ?? 0, favorite ?? 0],
        (err, result) => {
            if (err) {
                console.error(err);
                return res.status(500).send('DB error');
            }

            res.status(201).send('Added');
        }
    );
});

// Delete task
app.delete('/api/todo/:id', (req, res) => {
    const id = req.params.id;
    const sql = 'DELETE FROM todo WHERE id = ?';

    con.query(sql, [id], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('DB error');
        }

        if (result.affectedRows !== 1) {
            return res.status(404).send('Task not found');
        }

        res.send('Deleted');
    });
});

app.listen(3000, () => console.log('Server is running at port 3000 ^_^'));
