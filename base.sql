DROP SCHEMA schedule1 CASCADE;
DROP ROLE IF EXISTS  schedule_login_mangir, schedule_admin_mangir, schedule_moderator_mangir, schedule_anonim_mangir;

BEGIN;
CREATE ROLE schedule_login_mangir LOGIN PASSWORD '503fmf2017ABC';
CREATE ROLE schedule_admin_mangir; 
GRANT schedule_admin_mangir TO schedule_login_mangir;
CREATE ROLE schedule_moderator_mangir;
GRANT schedule_moderator_mangir TO schedule_login_mangir;
CREATE ROLE schedule_anonim_mangir;
GRANT schedule_anonim_mangir TO schedule_login_mangir;

CREATE SCHEMA schedule1;
SET search_path TO schedule1;
CREATE TYPE audience AS ENUM ('lecture','practice','laboratory');
CREATE TYPE lecture AS ENUM ('lecture','practice','laboratory');
CREATE TYPE parity AS ENUM ('even','odd','constantly');
CREATE TYPE education_form  AS ENUM ('full-time', 'extramural', 'part-time');
CREATE TYPE role AS ENUM ('schedule_admin','schedule_moderator','schedule_anonim');
CREATE TYPE jwt AS (role role, person_id int);

CREATE TABLE faculty(
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE teachers(
    id SERIAL PRIMARY KEY,
    first_name   TEXT NOT NULL,
    last_name    TEXT NOT NULL,
    patronymic  TEXT NOT NULL,
    science_degree TEXT NOT NULL,
    faculty_id INTEGER REFERENCES faculty(id) NOT NULL
);

GRANT SELECT, UPDATE, DELETE, INSERT ON teachers TO schedule_admin_mangir, schedule_moderator_mangir;
GRANT SELECT ON teachers TO schedule_anonim_mangir;

GRANT SELECT, UPDATE, DELETE, INSERT ON faculty TO schedule_admin_mangir, schedule_moderator_mangir;
GRANT SELECT ON faculty TO schedule_anonim_mangir;

CREATE TABLE classroom(
    id SERIAL PRIMARY KEY,
    number VARCHAR(50) NOT NULL,
    capacity Int NOT NULL,
    housing VARCHAR(5) NOT NULL,
    type audience NOT NULL
);

GRANT SELECT, UPDATE, DELETE, INSERT ON classroom TO schedule_admin_mangir, schedule_moderator_mangir;
GRANT SELECT ON classroom TO schedule_anonim_mangir;

CREATE TABLE groups(
    id SERIAL PRIMARY KEY,
    name   VARCHAR(20) NOT NULL,
    number_of_students Int NOT NULL,
    faculty_id INTEGER REFERENCES faculty(id) NOT NULL,
    education_form education_form NOT NULL
    
);

GRANT SELECT, UPDATE, DELETE, INSERT ON groups TO schedule_admin_mangir, schedule_moderator_mangir;
GRANT SELECT ON groups TO schedule_anonim_mangir;

CREATE TABLE discipline(
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    group_id INTEGER REFERENCES groups(id) NOT NULL,
    type lecture
);

GRANT SELECT, UPDATE, DELETE, INSERT ON discipline TO schedule_admin_mangir, schedule_moderator_mangir;
GRANT SELECT ON discipline TO schedule_anonim_mangir;

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

GRANT SELECT, UPDATE, DELETE, INSERT ON schedule TO schedule_admin_mangir, schedule_moderator_mangir;
GRANT SELECT ON schedule TO schedule_anonim_mangir;


CREATE TABLE person (
    id SERIAL PRIMARY KEY, 
    name VARCHAR(100)
);

CREATE TABLE account (
    id SERIAL PRIMARY KEY,
    login VARCHAR(20) NOT NULL UNIQUE,
    password VARCHAR(20) NOT NULL,
    role role NOT NULL,
    person_id INTEGER REFERENCES person(id),
    faculty_id INTEGER REFERENCES faculty(id) NOT NULL
);



ALTER TABLE schedule ENABLE ROW LEVEL SECURITY;
CREATE POLICY select_schedule ON schedule FOR SELECT TO schedule_admin_mangir, schedule_moderator_mangir, schedule_anonim_mangir USING (true);
CREATE POLICY update_schedule_admin ON schedule FOR UPDATE TO schedule_admin_mangir USING (true);
CREATE POLICY insert_schedule_admin ON schedule FOR INSERT TO schedule_admin_mangir WITH CHECK (true);
CREATE POLICY delete_schedule_admin ON schedule FOR DELETE TO schedule_admin_mangir USING (true);

CREATE POLICY update_schedule_moderator ON schedule FOR UPDATE TO schedule_moderator_mangir USING ((SELECT faculty_id FROM account WHERE person_id=current_setting('jwt.person_id')::int)=faculty_id);
CREATE POLICY insert_schedule_moderator ON schedule FOR INSERT TO schedule_moderator_mangir WITH CHECK ((SELECT faculty_id FROM account WHERE person_id=current_setting('jwt.person_id')::int)=faculty_id);
CREATE POLICY delete_schedule_moderator ON schedule FOR DELETE TO schedule_moderator_mangir USING ((SELECT faculty_id FROM account WHERE person_id=current_setting('jwt.person_id')::int)=faculty_id);

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

COMMIT;

--------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION she1(fuck int, gr int default 0, teach int default 0, days int default 0, pair int default 0) 
   RETURNS SETOF schedule1.schedule AS
$$
   SELECT * FROM schedule1.schedule where 
	schedule1.schedule.faculty_id=fuck 
	and (schedule1.schedule.group_id=gr or gr=0) 
	and (schedule1.schedule.teacher_id=teach or teach=0) 
	and (schedule1.schedule.days=days or days=0) 
	and (schedule1.schedule.pair=pair or pair=0) 
$$
   LANGUAGE SQL;	

select * from she1(1,1,1,1,1);
