import ballerina/http;
import ballerina/log;

// Data types for Programme and Course
type Programme record {
    string code;
    string title;  
    string faculty;
    string department;
    int nqfLevel;
    string registrationDate;
    Course[] courses;
};

type Course record {
    string code;
    string name;
    int nqfLevel;
};

// In-memory data store
map<Programme> programmeStore = {};

// Helper function to check if a programme is due for review
function isDueForReview(string registrationDate) returns boolean {
    int year = check int:fromString(registrationDate.substring(0, 4));
    return (2024 - year) >= 5;
}

service /programmes on new http:Listener(8080) {

    resource function post newProgramme(http:Caller caller, http:Request req) returns error? {
        json jsonPayload = check req.getJsonPayload();
        Programme newProgramme = check jsonPayload.cloneWithType(Programme); // Corrected type casting
        programmeStore[newProgramme.code] = newProgramme;
        check caller->respond("Programme added successfully");
    }

    resource function get allProgrammes(http:Caller caller, http:Request req) returns error? {
        check caller->respond(programmeStore);
    }

    resource function put updateProgramme(http:Caller caller, http:Request req, string code) returns error? {
        json jsonPayload = check req.getJsonPayload();
        Programme updatedProgramme = check jsonPayload.cloneWithType(Programme); // Corrected type casting
        if programmeStore.hasKey(code) {
            programmeStore[code] = updatedProgramme;
            check caller->respond("Programme updated successfully");
        } else {
            check caller->respond("Programme not found");
        }
    }

    resource function get getProgrammeByCode(http:Caller caller, string code) returns error? {
        if programmeStore.hasKey(code) {
            check caller->respond(programmeStore[code]);
        } else {
            check caller->respond("Programme not found");
        }
    }

    resource function delete deleteProgramme(http:Caller caller, string code) returns error? {
        if programmeStore.hasKey(code) {
            programmeStore.remove(code);
            check caller->respond("Programme deleted successfully");
        } else {
            check caller->respond("Programme not found");
        }
    }

    resource function get programmesDueForReview(http:Caller caller) returns error? {
        Programme[] dueProgrammes = [];
        foreach var programme in programmeStore {  // Corrected loop pattern
            if isDueForReview(programme.registrationDate) {
                dueProgrammes.push(programme);
            }
        }
        check caller->respond(dueProgrammes);
    }

    resource function get programmesByFaculty(http:Caller caller, string faculty) returns error? {
        Programme[] facultyProgrammes = [];
        foreach var programme in programmeStore {  // Corrected loop pattern
            if programme.faculty == faculty {
                facultyProgrammes.push(programme);
            }
        }
        check caller->respond(facultyProgrammes);
    }
}
