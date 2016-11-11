(function (L) {
    var _this = null;
    L.KVStore = L.KVStore || {};
    _this = L.KVStore = {
        data: {
        },

        init: function () {
            L.Common.loadConfigs("kvstore", _this, true);
            _this.initEvents();
        },

        initEvents: function(){
            
        },

       
    };
}(APP));
