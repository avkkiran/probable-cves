
DROP TRIGGER IF EXISTS pCVE_audit ON probable_cves;
DROP TABLE IF EXISTS probable_cves_review_history;
DROP TABLE IF EXISTS probable_cves;
DROP TYPE IF EXISTS probable_cves_ecosystem_enum;
DROP TYPE IF EXISTS probable_cves_cause_enum;
DROP TYPE IF EXISTS probable_cves_review_enum;
create type probable_cves_ecosystem_enum as enum(
    'maven', 
    'python', 
    'npm', 
    'golang'
);
create type probable_cves_cause_enum as enum(
    'Issue', 
    'Pull Request', 
    'Commit', 
    'Issue Comment',
    'PR Comment',
    'Commit Comment'
);
create type probable_cves_review_enum as enum(
    'Not Reviewed', 
    'Reviewed - Probable CVE', 
    'Reviewed - Not a CVE', 
    'Not sure'
);

create table probable_cves (
    id serial primary key, 
    ecosystem probable_cves_ecosystem_enum NOT NULL,
    repository  VARCHAR (50) NOT NULL,
    repo_url  VARCHAR (500) NOT NULL,
    package VARCHAR (500) NOT NULL, 
    cause_type probable_cves_cause_enum NOT NULL,
    issue_date DATE,
    issue_url JSONB,
    fixed_date DATE,
    fixed_url JSONB,
    commit_date DATE,
    commit_url JSONB,
    identified_date DATE,
    identified_url JSONB,
    files_changed JSONB,
    review_status probable_cves_review_enum NOT NULL DEFAULT 'Not Reviewed',
    reviewed_at TIMESTAMP,
    reviewed_by VARCHAR(255),
    cve_id VARCHAR(255),
    cve_date DATE,
    flagged_score VARCHAR(25) NOT NULL,
    flagged_at TIMESTAMP NOT NULL DEFAULT NOW(), 
    flagged_comments JSONB,
    additional_info JSONB,
    review_comments VARCHAR(255)
);

/*
16 columns need to be inserted while inserting from CSV file:
repository, ecosystem, repo_url, package, cause_type, issue_url, issue_date, fixed_url, fixed_date,  commit_url, commit_date, identified_url, identified_date, files_changed, flagged_score, flagged_at

Example import:
copy probable_cves (repository, ecosystem, repo_url, package, cause_type, issue_url, issue_date, fixed_url, fixed_date,  commit_url, commit_date, identified_url, identified_date, files_changed, flagged_score, flagged_at) FROM '/Users/sadhikar/Documents/Work/cve_test/backend/Test2.csv' DELIMITER ';' NULL as 'null';

Example import using psql command:
psql -h sadhikar-bayesiandb.cqkrox9mwgno.us-east-1.rds.amazonaws.com -p 5432 -d coreapi  -U coreapi -c "\copy probable_cves (repository, ecosystem, repo_url, package, cause_type, issue_url, issue_date, fixed_url, fixed_date,  commit_url, commit_date, identified_url, identified_date, files_changed, flagged_score, flagged_at) FROM '/Users/sadhikar/Documents/Work/cve_test/backend/Test2.csv' DELIMITER ';' NULL as 'null';"

Example insert statement:
INSERT INTO probable_cves (ecosystem, repository, repo_url, package, cause_type, commit_url, commit_date, flagged_score, flagged_at) 
VALUES ('golang', 'kubernetes/dns', 'https://github.com/kubernetes/dns', 'kubernetes/dns','Commit','["https://github.com/kubernetes/dns/commit/83379281bee93833a3aaa39c00c220bb78f7e21a"]', '10/14/2017', '80%', '2/20/2018');

*/

create table probable_cves_history (
history_id serial primary key,
p_id INTEGER NOT NULL REFERENCES probable_cves(id),
reviewed_at TIMESTAMP,
reviewed_by VARCHAR(255),
review_status probable_cves_review_enum,
review_comments VARCHAR(255),
last_modified_at TIMESTAMP DEFAULT NOW(),
row_data JSONB,
operation VARCHAR(10) NOT NULL
);

CREATE OR REPLACE FUNCTION proc_pCVE_audit() RETURNS TRIGGER AS $pCVE_audit$
    BEGIN
        --
        -- Create a row in emp_audit to reflect the operation performed on emp,
        -- make use of the special variable TG_OP to work out the operation.
        --
        IF (TG_OP = 'UPDATE') THEN
            IF (OLD.review_status = NEW.review_status) THEN
                INSERT INTO probable_cves_history 
                (p_id,reviewed_at,reviewed_by,review_status,review_comments,operation,row_data) 
                SELECT OLD.id,OLD.reviewed_at,OLD.reviewed_by,OLD.review_status,OLD.review_comments,'Update',row_to_json(OLD.*);
                RETURN OLD;
            ELSE
                INSERT INTO probable_cves_history 
                (p_id,reviewed_at,reviewed_by,review_status,review_comments,operation,row_data) 
                SELECT OLD.id,OLD.reviewed_at,OLD.reviewed_by,OLD.review_status,OLD.review_comments,'Status',row_to_json(OLD.*);
                RETURN OLD;
            END IF;
        -- ELSIF (TG_OP = 'INSERT') THEN
        --     INSERT INTO probable_cves_review_history 
        --     (p_id,reviewed_at,reviewed_by,review_status,review_comments,operation,row_data) 
        --     SELECT NEW.id,NEW.reviewed_at,NEW.reviewed_by,NEW.review_status,NEW.review_comments,'Insert',row_to_json(NEW.*);
        --     RETURN NEW;
        -- ELSIF (TG_OP = 'DELETE') THEN
        --     INSERT INTO probable_cves_review_history 
        --     (p_id,reviewed_at,reviewed_by,review_status,review_comments,operation,row_data) 
        --     SELECT OLD.id,OLD.reviewed_at,OLD.reviewed_by,OLD.review_status,OLD.review_comments,'Delete',row_to_json(OLD.*);
        --     RETURN OLD;
        END IF;
        RETURN NULL; -- result is ignored since this is an AFTER trigger
    END;

$pCVE_audit$ LANGUAGE plpgsql;

CREATE TRIGGER pCVE_audit
AFTER INSERT OR UPDATE OR DELETE ON probable_cves
    FOR EACH ROW EXECUTE PROCEDURE proc_pCVE_audit();