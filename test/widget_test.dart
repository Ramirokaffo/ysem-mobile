import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ysem/core/network/api_exception.dart';

void main() {
  group('ApiException.depuisDio', () {
    RequestOptions requete() => RequestOptions(path: 'auth/connexion/');

    test("lit detail, code et erreurs du corps normalisé de l'API", () {
      final e = ApiException.depuisDio(DioException(
        requestOptions: requete(),
        response: Response(
          requestOptions: requete(),
          statusCode: 400,
          data: {
            'detail': 'Refusé',
            'code': 'formulaire_invalide',
            'erreurs': {
              'motif': ['Ce champ est obligatoire.'],
            },
          },
        ),
      ));
      expect(e.code, 'formulaire_invalide');
      expect(e.message, 'Refusé');
      expect(e.estFormulaireInvalide, isTrue);
      expect(e.erreurDuChamp('motif'), 'Ce champ est obligatoire.');
    });

    test('traduit une coupure réseau en code client', () {
      final e = ApiException.depuisDio(DioException(
        requestOptions: requete(),
        type: DioExceptionType.connectionError,
      ));
      expect(e.code, ApiException.codeReseau);
      expect(e.estErreurReseau, isTrue);
    });

    test('reconnaît les codes qui ferment la session', () {
      final e = ApiException.depuisDio(DioException(
        requestOptions: requete(),
        response: Response(
          requestOptions: requete(),
          statusCode: 401,
          data: {'detail': 'Reconnectez-vous.', 'code': 'mot_de_passe_change'},
        ),
      ));
      expect(e.sessionPerdue, isTrue);
    });
  });
}
