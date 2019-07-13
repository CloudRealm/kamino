import 'package:kamino/models/content/content.dart';

class Genre {

  static const List movie = [
    {
      "id": 28,
      "name": "Action",
      "banner": "/aUVCJ0HkcJIBrTJYPnTXta8h9Co.jpg"
    },
    {
      "id": 12,
      "name": "Adventure",
      "banner": "/9SOQMXDwu314k22DK6ObJU1Ebcq.jpg"
    },
    {
      "id": 16,
      "name": "Animation",
      "banner": "/h3KN24PrOheHVYs9ypuOIdFBEpX.jpg"
    },
    {
      "id": 35,
      "name": "Comedy",
      "banner": "/l6jEz6DvnjaPnuWnVseSFJlxDoZ.jpg"
    },
    {
      "id": 80,
      "name": "Crime",
      "banner": "/1MUokmbc3qGXj69R8DyM6etF46Q.jpg"
    },
    {
      "id": 99,
      "name": "Documentary",
      "banner": "/efYGFJ5ySPlHaT8vYMyRJHm52qY.jpg"
    },
    {
      "id": 18,
      "name": "Drama",
      "banner": "/93xA62uLd5CwMOAs37eQ7vPc1iV.jpg"
    },
    {
      "id": 10751,
      "name": "Family",
      "banner": "/mabuNsGJgRuCTuGqjFkWe1xdu19.jpg"
    },
    {
      "id": 14,
      "name": "Fantasy",
      "banner": "/yNbh6FjfkSY7CJjsAqheWWx8Yoz.jpg"
    },
    {
      "id": 36,
      "name": "History",
      "banner": "/3lZuky17k1ihovh6mvFyGfgLIi4.jpg"
    },
    {
      "id": 27,
      "name": "Horror",
      "banner": "/6BDZOPnZwcouwBO1dIEI0QGQeLv.jpg"
    },
    {
      "id": 10402,
      "name": "Music",
      "banner": "/wqtaHWOEZ3rXDJ8c6ZZShulbo18.jpg"
    },
    {
      "id": 9648,
      "name": "Mystery",
      "banner": "/rURV5xPzt9ZxEXAc4OQmxchGyZ8.jpg"
    },
    {
      "id": 10749,
      "name": "Romance",
      "banner": "/xWuySM8JChXJAbfGQ9AERsLY80Q.jpg"
    },
    {
      "id": 878,
      "name": "Science Fiction",
      "banner": "/10csMIye4Vmr5lJpx3cdmMN8FOT.jpg"
    },
    /*{
      "id": 10770,
      "name": "TV Movie",
      "banner": "/oAsnQc9jAlAxknnd7YBjWLEhkzm.jpg"
    },*/
    {
      "id": 53,
      "name": "Thriller",
      "banner": "/rxYG6Sj95as9rv9wKIHUx6ATWd3.jpg"
    },
    {
      "id": 10752,
      "name": "War",
      "banner": "/6ELJEzQJ3Y45HczvreC3dg0GV5R.jpg"
    },
    {
      "id": 37,
      "name": "Western",
      "banner": "/qUcmEqnzIwlwZxSyTf3WliSfAjJ.jpg"
    }
  ];

  static const List tv = [
    {
      "id": 10759,
      "name": "Action & Adventure",
      "banner": "/3Xfx6SMjea6uZXnHj8I18AC4T7G.jpg"
    },
    {
      "id": 16,
      "name": "Animation",
      "banner": "/sygNC6NF0OEPP5ckXii5NkRLMVg.jpg"
    },
    {
      "id": 35,
      "name": "Comedy",
      "banner": "/64BUMjqFnfs3qKKQtwOHPIz224f.jpg"
    },
    {
      "id": 80,
      "name": "Crime",
      "banner": "/jHyGUhWBMif5AD6mImr6anYyTlJ.jpg"
    },
    {
      "id": 99,
      "name": "Documentary",
      "banner": "/bPySXNfMaBhjwSlCaqQxIcDUqOm.jpg"
    },
    {
      "id": 18,
      "name": "Drama",
      "banner": "/a3G7FsQNfo9mrnZtXN3yaDQhAgz.jpg"
    },
    {
      "id": 10751,
      "name": "Family",
      "banner": "/sD3OAmfxHRXWmZFROjRRL3HcPXj.jpg"
    },
    {
      "id": 10762,
      "name": "Kids",
      "banner": "/gV2FiYtScFdixj4FtmMjtm02i1y.jpg"
    },
    {
      "id": 9648,
      "name": "Mystery",
      "banner": "/8AdmUPTyidDebwIuakqkSt6u1II.jpg"
    },
    {
      "id": 10763,
      "name": "News",
      "banner": "/3eCg6wiLCIy3gY7VJANPF2NP3q3.jpg"
    },
    {
      "id": 10764,
      "name": "Reality",
      "banner": "/zRdzzZAHdrA2osVUuPfXKMmCFmJ.jpg"
    },
    {
      "id": 10765,
      "name": "Sci-Fi & Fantasy",
      "banner": "/8ZerYKvIaNUJZvAHXYTQu4qTwFw.jpg"
    },
    {
      "id": 10767,
      "name": "Talk",
      "banner": "/n5mBoQltnj28gY0m3s1LOL6okqU.jpg"
    },
    {
      "id": 10768,
      "name": "War & Politics",
      "banner": "/gYdHXIZ3BsharMLi2ykHItPE9CI.jpg"
    },
    {
      "id": 37,
      "name": "Western",
      "banner": "/45rk1PQjiTvEPzi0yBfYl0bdzz3.jpg"
    }
  ];

  static String getFontImagePath(ContentType content, int genreId){
    String mediaType = content == ContentType.TV_SHOW ? "tv" : "movie";
    return "assets/genre/${getRawContentType(content)}/${resolveGenreName(mediaType, genreId)}.svg";
  }

  static String resolveGenreName(String mediaType, int genreId){
    switch(mediaType){
      case 'tv':
        return Genre.tv.firstWhere((genre) => genre['id'] == genreId)['name'];
      case 'movie':
        return Genre.movie.firstWhere((genre) => genre['id'] == genreId)['name'];
      default:
        return null;
    }
  }

}

List<String> resolveGenreNames(List genreIds, String mediaType) {

  Function getNames = (genres) => genres.where(
          (genre) => genreIds.contains(genre['id'])
  ).map((genre) => genre['name']).toList().cast<String>();

  switch(mediaType){
    case 'tv':
      return getNames(Genre.tv);
    case 'movie':
      return getNames(Genre.movie);
    default:
      return [];
  }

}