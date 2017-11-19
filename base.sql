/*RESET ROLE;
DROP SCHEMA schedule1 CASCADE;*/

BEGIN;

CREATE SCHEMA schedule1;
SET search_path TO schedule1;

CREATE TYPE audience AS ENUM ('lecture','practice','laboratory');
CREATE TYPE lecture AS ENUM ('lecture','practice','laboratory');
CREATE TYPE parity AS ENUM ('even','odd','constantly');

CREATE TABLE faculty(
    id SERIAL PRIMARY KEY,
    name TEXT
);
 
CREATE TABLE teachers(
    id SERIAL PRIMARY KEY,
    name   TEXT NOT NULL UNIQUE,
    science_degree TEXT NOT NULL
);

CREATE TABLE classroom(
    id SERIAL PRIMARY KEY,
    number VARCHAR(50) NOT NULL UNIQUE,
    capacity Int NOT NULL,
    housing VARCHAR(5) NOT NULL,
    type audience NOT NULL
);

CREATE TABLE groups(
    id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE,
    number_of_students Int NOT NULL,
    faculty_id INTEGER REFERENCES faculty(id) NOT NULL
);

CREATE TABLE discipline(
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    group_id INTEGER REFERENCES groups(id) NOT NULL,
    type lecture,
    teacher_id INTEGER REFERENCES teachers(id) NOT NULL,
    classroom_id INTEGER REFERENCES classroom(id) NOT NULL
);

CREATE DOMAIN day_week AS INT
CHECK(
   VALUE BETWEEN 1 and 6
);

CREATE DOMAIN pair_number AS INT
CHECK(
   VALUE BETWEEN 1 and 8
);

CREATE TABLE schedule(
    group_id INTEGER REFERENCES groups(id) NOT NULL,
    discipline_id INTEGER REFERENCES discipline(id)  NOT NULL,
    teacher_id INTEGER REFERENCES teachers(id) NOT NULL,
    classroom_id INTEGER REFERENCES classroom(id)  NOT NULL,
    faculty_id INTEGER REFERENCES faculty(id) NOT NULL,
    days day_week  NOT NULL,
    pair pair_number  NOT NULL,
    PRIMARY KEY (group_id, discipline_id,teacher_id,classroom_id,days,pair)
);

CREATE TABLE person(
    id SERIAL PRIMARY KEY, 
    name VARCHAR(100) NOT NULL
);

CREATE TABLE account (
    id SERIAL PRIMARY KEY,
    login VARCHAR(20) NOT NULL UNIQUE,
    password VARCHAR(20) NOT NULL,
    person_id INTEGER REFERENCES person(id)
);

/*CREATE ROLE user_mangir;
CREATE ROLE admin_mangir;*/

CREATE TYPE role AS ENUM ('user_mangir', 'admin_mangir');

CREATE TYPE jwt AS (role role, person_id int);

CREATE OR REPLACE FUNCTION change_password(password varchar(20), person_id int) RETURNS void AS 
$$
begin
  UPDATE account SET hash = crypt(password, gen_salt('md5')) WHERE account.id = change_password.person_id;
end;
$$ 
LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION authentication(login varchar(20), password varchar(20)) RETURNS jwt AS 
$$
declare ac account;
begin
  SELECT * INTO ac FROM account WHERE account.login = authentication.login;
  if ac.hash = crypt(password, ac.hash) THEN  
    RETURN (ac.role, ac.person_id)::jwt;
  ELSE RETURN NULL;
  end if;
end;
$$ 
LANGUAGE plpgsql SECURITY DEFINER;

GRANT admin_mangir, user_mangir TO mangir;

GRANT USAGE ON SCHEMA schedule1 TO admin_mangir, user_mangir;
GRANT SELECT, UPDATE, DELETE ON discipline, teachers, classroom, groups TO admin_mangir;
GRANT SELECT ON account, person TO admin_mangir;
GRANT ALL ON schedule TO admin_mangir;

ALTER TABLE discipline ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE classroom ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE faculty ENABLE ROW LEVEL SECURITY;

/*
CREATE POLICY write_discipline ON discipline FOR UPDATE TO admin_mangir USING (current_setting('jwt.user_id')::int=person_id);
CREATE POLICY delete_discipline ON discipline FOR DELETE TO admin_mangir USING (current_setting('jwt.user_id')::int=person_id);
CREATE POLICY write_teachers ON teachers FOR DELETE TO admin_mangir USING (current_setting('jwt.user_id')::int=person_id);
CREATE POLICY delete_teachers ON teachers FOR DELETE TO admin_mangir USING (current_setting('jwt.user_id')::int=person_id);
CREATE POLICY write_classroom ON classroom FOR DELETE TO admin_mangir USING (current_setting('jwt.user_id')::int=person_id);
CREATE POLICY delete_classroom ON classroom FOR DELETE TO admin_mangir USING (current_setting('jwt.user_id')::int=person_id);
CREATE POLICY write_groups ON groups FOR DELETE TO admin_mangir USING (current_setting('jwt.user_id')::int=person_id);
CREATE POLICY delete_groups ON groups FOR DELETE TO admin_mangir USING (current_setting('jwt.user_id')::int=person_id);
CREATE POLICY write_faculty ON faculty FOR DELETE TO admin_mangir USING (current_setting('jwt.user_id')::int=person_id);
CREATE POLICY delete_faculty ON faculty FOR DELETE TO admin_mangir USING (current_setting('jwt.user_id')::int=person_id);
*/

COMMIT;
