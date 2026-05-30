// SPDX-License-Identifier: MIT - лицензия MIT, разрешает свободное использование кода
pragma solidity ^0.8.20; - версия компилятора Solidity, ^ означает совместимость с 0.8.x до 0.9.0

// Импорт контрактов из библиотеки OpenZeppelin - прошедшие аудит реализации стандартов
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; - базовая реализация стандарта ERC-721
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; - расширение для хранения URI токена в storage контракта
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; - расширение, добавляющее функциональность сжигания токенов
import "@openzeppelin/contracts/access/AccessControl.sol"; - реализация ролевой модели управления доступом

contract SampleNFT is ERC721, ERC721URIStorage, ERC721Burnable, AccessControl {
    // Идентификатор роли минтера - хеш строки "MINTER_ROLE", 32 байта
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    // Счетчик для генерации идентификаторов токенов
    uint256 private _nextTokenId;

    // URI метаданных токена, загруженных в IPFS, используется шлюз ipfs.io для HTTP-доступа
    string private constant TOKEN_URI = "https://ipfs.io/ipfs/bafkreierdih4qwmessannmhvzbxlekpoxnmpl3455cl7k6vvdqc34w5dsq";

    // Конструктор контракта, вызывается однократно при деплое в сеть
    // initialAdmin - адрес администратора ролей
    // initialMinter - адрес, получающий право минта токенов
    constructor(address initialAdmin, address initialMinter)
        ERC721("SampleNFT", "SNFT") - имя коллекции и её символ
    {
        // Назначение роли администратора по умолчанию
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        // Назначение роли минтера
        _grantRole(MINTER_ROLE, initialMinter);
    }

    // Функция безопасного минта одного токена на указанный адрес
    // Модификатор onlyRole ограничивает доступ - только адреса с ролью MINTER_ROLE
    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _nextTokenId++; - присвоение текущего идентификатора с последующим инкрементом
        _safeMint(to, tokenId); - безопасный минт с проверкой возможности получателя принять NFT
        _setTokenURI(tokenId, TOKEN_URI); - привязка URI метаданных к созданному токену
    }

    // Функция массового минта токенов для экономии газа при создании нескольких NFT
    // account - адрес получателя
    // amount - количество создаваемых токенов
    // data - дополнительные данные, логируются в событии
    function mint(address account, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        for(uint256 i; i < amount; ++i) {
            uint256 tokenId = _nextTokenId++;
            _mint(account, tokenId); - обычный минт без проверки onERC721Received, дешевле по газу
            _setTokenURI(tokenId, TOKEN_URI);
        }
        // Эмиссия события при наличии дополнительных данных
        if (data.length > 0) {
            emit BatchMintWithData(account, amount, data);
        }
    }

    // Событие массового минта с дополнительными данными
    // indexed для поля to позволяет фильтровать события по адресу получателя
    event BatchMintWithData(address indexed to, uint256 amount, bytes data);

    // Переопределение функции tokenURI для разрешения конфликта множественного наследования
    // ERC721 и ERC721URIStorage оба определяют эту функцию
    // super вызывает реализацию из ERC721URIStorage согласно C3-линеаризации
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // Переопределение supportsInterface согласно стандарту ERC-165
    // Три родительских контракта реализуют эту функцию
    // super последовательно вызывает все версии по цепочке наследования
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
