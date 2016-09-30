



CREATE TABLE users (
    id serial,
    first_name character varying(30),
    last_name character varying(30),
    email character varying(30),
    from_date timestamp without time zone DEFAULT now(),
    last_date timestamp without time zone DEFAULT now(),
    PRIMARY KEY (id),
    CONSTRAINT users_check
        CHECK (last_date >= from_date)
);


CREATE DOMAIN gender AS varchar(1)
CHECK(
   VALUE IN (NULL, 'm', 'f')
);

CREATE TABLE fb_users (
    id bigint primary key,
    usr_id integer not null,
    profile_pic text,
    locale character varying(30),
    timezone varchar(8),
    gender gender,
    foreign key (usr_id)
        references users(id)
        on delete Cascade
        on update cascade
);


CREATE TABLE tg_users (
    id integer primary key,
    usr_id integer not null,
    user_name character varying(30),
    foreign key (usr_id)
        references users(id)
        on delete Cascade
        on update cascade
);

CREATE TABLE images(
    id CHAR(8) PRIMARY KEY,
    url VARCHAR(200)
);


CREATE TABLE doleances(
usr_id integer not null,
msg varchar(300),
img_id CHAR(8),
date timestamp DEFAULT now(),
primary key (usr_id, msg, img_id),
foreign key (usr_id)
        references users(id)
        on delete Cascade
        on update cascade,
foreign key (img_id)
        references images(id)
        on delete Cascade
        on update cascade
);

-- TODO
-- delimiter //
-- CREATE trigger updateLastDate
-- after insert on doleances
-- begin
-- for each row
-- update users set last_date = now() where id = new.usr_id;
-- end;//
-- delimiter ;
