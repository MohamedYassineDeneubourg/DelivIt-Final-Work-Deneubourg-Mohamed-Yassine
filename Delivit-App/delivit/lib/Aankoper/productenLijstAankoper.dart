import 'package:delivit/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductenLijstAankoper extends StatefulWidget {
  @override
  _ProductenLijstAankoperState createState() => _ProductenLijstAankoperState();
}

class _ProductenLijstAankoperState extends State<ProductenLijstAankoper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: White,
      appBar: AppBar(
        backgroundColor: White,
        textTheme: TextTheme(
            title: TextStyle(
                color: Geel,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                fontFamily: "Montserrat")),
        centerTitle: true,
        title: new Text("KIES JE PRODUCTEN"),
      ),
      body: storeTab(context),
    );
  }
}

Widget storeTab(BuildContext context) {
  List<Map> producten = [
    {
      "name": "Coca-Cola",
      "image":
          "https://assets.lyreco.com/is/image/lyrecows/2018-3117696?locale=LU_fr&id=8yQqP0&fmt=jpg&fit=constrain,1&wid=430&hei=430",
      "price": "\$45.12",
      "userLiked": true,
      "discount": 2,
    },    {
      "name": "Coca-Cola",
      "image":
          "https://assets.lyreco.com/is/image/lyrecows/2018-3117696?locale=LU_fr&id=8yQqP0&fmt=jpg&fit=constrain,1&wid=430&hei=430",
      "price": "\$45.12",
      "userLiked": true,
      "discount": 2,
    },    {
      "name": "Coca-Cola",
      "image":
          "https://assets.lyreco.com/is/image/lyrecows/2018-3117696?locale=LU_fr&id=8yQqP0&fmt=jpg&fit=constrain,1&wid=430&hei=430",
      "price": "\$45.12",
      "userLiked": true,
      "discount": 2,
    },    {
      "name": "Coca-Cola",
      "image":
          "https://assets.lyreco.com/is/image/lyrecows/2018-3117696?locale=LU_fr&id=8yQqP0&fmt=jpg&fit=constrain,1&wid=430&hei=430",
      "price": "\$45.12",
      "userLiked": true,
      "discount": 2,
    },    {
      "name": "Coca-Cola",
      "image":
          "https://assets.lyreco.com/is/image/lyrecows/2018-3117696?locale=LU_fr&id=8yQqP0&fmt=jpg&fit=constrain,1&wid=430&hei=430",
      "price": "\$45.12",
      "userLiked": true,
      "discount": 2,
    },
  ];

  return ListView(children: <Widget>[
    headerTopCategories(),
    deals('Drinks Parol', onViewMore: () {}, items: <Widget>[
      for (var product in producten)
        Container(
          width: 180,
          height: 180,
          // color: Colors.red,
          margin: EdgeInsets.only(left: 20),
          child: Stack(
            children: <Widget>[
              Container(
                  width: 180,
                  height: 180,
                  child: RaisedButton(
                      color: White,
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      onPressed: () {},
                      child: Hero(
                          transitionOnUserGestures: true,
                          tag: product["name"],
                          child: Image.network(product['image'], width: 100)))),
              Positioned(
                bottom: 10,
                right: 0,
                child: FlatButton(
                  padding: EdgeInsets.all(20),
                  shape: CircleBorder(),
                  onPressed: () {},
                  child: Icon(
                    (product['userLiked'])
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: (product['userLiked']) ? Geel : GrijsDark,
                    size: 30,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Text(' '),
              ),
              Positioned(
                  top: 10,
                  left: 10,
                  child: (product['discount'] != null)
                      ? Container(
                          padding: EdgeInsets.only(
                              top: 5, left: 10, right: 10, bottom: 5),
                          decoration: BoxDecoration(
                              color: Colors.grey[600],
                              borderRadius: BorderRadius.circular(50)),
                          child: Text(
                              '-' + product['discount'].toString() + '%',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        )
                      : SizedBox(width: 0))
            ],
          ),
        )
    ])
  ]);
}

Widget sectionHeader(String headerTitle, {onViewMore}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Container(
        margin: EdgeInsets.only(left: 15, top: 10),
        child: Text(
          headerTitle,
        ),
      ),
      Container(
        margin: EdgeInsets.only(left: 15, top: 2),
        child: FlatButton(
          onPressed: onViewMore,
          child: Text('View all ›'),
        ),
      )
    ],
  );
}

// wrap the horizontal listview inside a sizedBox..
Widget headerTopCategories() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      sectionHeader('All Categories', onViewMore: () {}),
      SizedBox(
        height: 130,
        child: ListView(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          children: <Widget>[
            headerCategoryItem('Frieds', FontAwesomeIcons.edit,
                onPressed: () {}),
            headerCategoryItem('Fast Food', FontAwesomeIcons.zhihu,
                onPressed: () {}),
            headerCategoryItem('Creamery', FontAwesomeIcons.poop,
                onPressed: () {}),
            headerCategoryItem('Hot Drinks', FontAwesomeIcons.radiation,
                onPressed: () {}),
            headerCategoryItem('Vegetables', FontAwesomeIcons.leaf,
                onPressed: () {}),
          ],
        ),
      )
    ],
  );
}

Widget headerCategoryItem(String name, IconData icon, {onPressed}) {
  return Container(
    margin: EdgeInsets.only(left: 15),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
            margin: EdgeInsets.only(bottom: 10),
            width: 65,
            height: 65,
            child: RaisedButton(
              color: White,
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: GrijsDark.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(6.0)),
              onPressed: onPressed,
              child: Icon(icon, size: 28, color: GrijsDark),
            )),
        Text(name)
      ],
    ),
  );
}

Widget deals(String dealTitle, {onViewMore, List<Widget> items}) {
  return Container(
    margin: EdgeInsets.only(top: 5),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        sectionHeader(dealTitle, onViewMore: onViewMore),
        SizedBox(
          height: 250,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: (items != null)
                ? items
                : <Widget>[
                    Container(
                      margin: EdgeInsets.only(left: 15),
                      child: Text(
                        'No items available at this moment.',
                      ),
                    )
                  ],
          ),
        )
      ],
    ),
  );
}
