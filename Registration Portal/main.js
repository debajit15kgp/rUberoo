// Your web app's Firebase configuration
var firebaseConfig = {
apiKey: "AIzaSyCVX8o-gY8_QYA4YlXP_RytqJWcU45eUxI",
authDomain: "ruberoo.firebaseapp.com",
projectId: "ruberoo",
storageBucket: "ruberoo.appspot.com",
messagingSenderId: "195252687836",
appId: "1:195252687836:web:9669a0b0eab99927c47519"
};
// Initialize Firebase
firebase.initializeApp(firebaseConfig);

var messagesRef = firebase.database().ref('messages');

document.getElementById('billingAddress').addEventListener('submit', submitForm);

function submitForm(e)
{
    e.preventDefault();

    // console.log("123");
    var placename = getInputVal("placename");
    var cityLat = getInputVal("cityLat");
    var cityLng = getInputVal("cityLng");
    var placeid = getInputVal("placeid"); 
    var pincode = getInputVal("postal_code");
    var state = getInputVal("state");
    var namebusiness = getInputVal("namebusiness");
    var nameowner = getInputVal("nameowner");
    var description = getInputVal("description");
    var planEle = document.getElementsByName("plan");
    var plan="normal";
    for(i=0;i<planEle.length;i++)
    {
        if(planEle[i].checked)
        {
            plan = planEle[i].value;
        }
    }
    // console.log(plan);

    saveMsg(placename, cityLat, cityLng, placeid, pincode, state, namebusiness, nameowner, description, plan);
    window.location.href="thank.html";
}

function getInputVal(id)
{
    return document.getElementById(id).value;
}

// save msg to firebase

function saveMsg(placename, cityLat, cityLng, placeid, pincode, state, namebusiness, nameowner, description, plan)
{
    var newMsg = messagesRef.push();
    newMsg.set({
        placename:placename, 
        cityLat:cityLat, 
        cityLng:cityLng, 
        placeid:placeid, 
        pincode:pincode, 
        state:state, 
        namebusiness:namebusiness, 
        nameowner:nameowner, 
        description:description, 
        plan:plan
    })
}
