const express = require('express');
const app = express();
const admin = require('firebase-admin');
const serviceAccount = require('./delivit-firebase-adminsdk-xk2xv-0a8c1cf28f.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();


var url = require('url');

function getFormattedUrl(req) {
  return url.format({
    protocol: req.protocol,
    host: req.get('host')
  });
}

const {
  resolve
} = require('path');
// Copy the .env.example in the root into a .env file in this folder
require('dotenv').config({
  path: './.env'
});
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

//app.use(express.static(process.env.STATIC_DIR));
app.use(
  express.json({
    // We need the raw body to verify webhook signatures.
    // Let's compute it only when hitting the Stripe webhook endpoint.
    verify: function (req, res, buf) {
      if (req.originalUrl.startsWith('/webhook')) {
        req.rawBody = buf.toString();
      }
    },
  })
);

app.use("/css", express.static('./css/'));

app.get('/', (req, res) => { //res.redirect(getFormattedUrl(req));
  const path = resolve('canceled.html');
  res.sendFile(path);
});

app.get('/canceled.html', (req, res) => {
  const path = resolve('canceled.html');
  res.sendFile(path);
});
app.get('/success.html', (req, res) => {
  const path = resolve('success.html');
  res.sendFile(path);
});


app.get('/payment', (req, res) => {

  console.log(currentHostUrl);
  if (req.query.amount != null && req.query.delivitemail != null && req.query.amount >= 100) {
    var currentHostUrl = getFormattedUrl(req);

    var stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
    var amount = parseInt(req.query.amount);
    var delivitemail = req.query.delivitemail;
    console.log(req.query);

    try {



      stripe.sources.create({
        type: 'bancontact',
        amount: amount,
        currency: 'eur',
        redirect: {
          return_url: `${currentHostUrl}/get?amount=${amount}&delivitemail=${delivitemail}`,
        },
        owner: {
          name: delivitemail,
          email: delivitemail
        }
      }, function (err, source) {
        console.log(source);
        console.log(err);
        // res.send(source.redirect.url);
        res.redirect(source.redirect.url);

      });
    } catch (e) {
      res.redirect(`${currentHostUrl}/canceled.html`);

    }

  } else {
    res.redirect(`${currentHostUrl}/canceled.html`);

  }


});


app.get('/get', async (req, res) => {
  var currentHostUrl = getFormattedUrl(req);

  console.log(req.query);
  try {
    stripe.charges.create({
        currency: 'eur',
        amount: req.query.amount,
        source: req.query.source,
        description: 'GET',
      },
      function (err, charge) {
        console.log(err);
        console.log(charge);
        if (err) {
          res.redirect(`${currentHostUrl}/canceled.html`);

        }
        if (charge != null) {


          console.log("STATUS : " + charge.status);
          console.log("PAID : " + charge.paid);
          console.log("EMAIL :" + req.query.delivitemail);
          var TotalePrijs = req.query.amount / 100;
          if (charge.paid == true && charge.status == "succeeded") {
            var d = new Date();
            var datestring = ("0" + d.getDate()).slice(-2) + "-" + ("0" + (d.getMonth() + 1)).slice(-2) + "-" +
              d.getFullYear() + " " + ("0" + d.getHours()).slice(-2) + ":" + ("0" + d.getMinutes()).slice(-2);

            collectionReferenceUsers = db.collection('Users').doc(req.query.delivitemail);

            collectionReferenceUsers.update({
              Portefeuille: admin.firestore.FieldValue.increment(parseFloat(TotalePrijs)),
              PortefeuilleHistoriek: admin.firestore.FieldValue.arrayUnion({
                "BestellingId": "Kaart: Geld toegevoegd",
                "Datum": datestring,
                "Type": "+",
                "TotalePrijs": TotalePrijs,
              }),
            });

            res.redirect(`${currentHostUrl}/success.html`);
          }
        }
        // asynchronously called
      }
    );
  } catch (e) {
    res.redirect(`${currentHostUrl}/canceled.html`);

  }
  console.log(req.query);



});

app.route('/payit').get(function (req, res) {
  var d = new Date();
  var datestring = ("0" + d.getDate()).slice(-2) + "-" + ("0" + (d.getMonth() + 1)).slice(-2) + "-" +
    d.getFullYear() + " " + ("0" + d.getHours()).slice(-2) + ":" + ("0" + d.getMinutes()).slice(-2);
  console.log(datestring);
  /*  let ts = Date.now();

      let date_ob = new Date(ts);
      let date = date_ob.getDate();
      let month = date_ob.getMonth() + 1;
      let year = date_ob.getFullYear();
      let dateString = year + "-" + month + "-" + date;
      // prints date & time in YYYY-MM-DD format
      console.log(year + "-" + month + "-" + date);
*/


  /* let citiesRef = db.collection('Conversations');
  citiesRef.get()
    .then(snapshot => {

      snapshot.forEach(doc => {
        console.log(doc.data());


        let doct = db.collection('Conversations').doc(doc.id);
        doct.update({
          LastMessageTime: Date.now()
        });
      });
    })
    .catch(err => {
      console.log('Error getting documents', err);
    });
*/
  /*
  let doct = db.collection('Global').doc('globalDocument');
  doct.update({
    CommunesBruxelles: ["Région de Bruxelles-Capitale", "Anderlecht", "Bruxelles Centre", "Ixelles", "Etterbeek", "Evere", "Ganshoren", "Jette", "Koekelberg", "Auderghem", "Schaerbeek", "Berchem-Sainte-Agathe", "Saint-Gilles", "Molenbeek-Saint-Jean", "Saint-Josse-ten-Noode", "Woluwe-Saint-Lambert", "Woluwe-Saint-Pierre", "Uccle", "Forest", "Watermael-Boitsfort"],
    CommunesPeripherie: ["Périphérie de Bruxelles-Capitale", "Asse", "Merchtem", "Meise", "Wemmel", "Grimbergen", "Vilvoorde", "Machelen", "Zaventem", "Kraainem", "Wezembeek-Oppem", "Tervuren", "Rhode-Saint-Genèse", "Linkebeek", " Leeuw-Saint-Pierre", "Drogenbos"]
 

  */



  /*   db.collection("Users").get().then(function (querySnapshot) {
        querySnapshot.forEach(function (doc) {
            doc.ref.update({
                Sexe: "Homme"
            });
        });
    });
*/
  res.send('Infinite money on /payitnow');
});

app.listen(process.env.PORT || 4242,
  () => console.log("Server is running..."));