package br.com.stimuli.loading.lazyloaders
{
	import flash.media.SoundLoaderContext;
	import flash.net.URLRequestHeader;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	
	import br.com.stimuli.loading.BulkLoader;
	import br.com.stimuli.loading.lazy_loader;
	import br.com.stimuli.loading.loadingtypes.LoadingItem;

	/**
	 *       @example Basic usage:<listing version="3.0">
	 var lazy : LazyXMLLoader = new LazyXMLLoader("sample-lazy.xml", "myBulkLoader");
	// listen to when the lazy loader has loaded the external definition
	lazy.addEventListener(Event.LAZY_LOADED, onLazyLoaded);
	// add regular events to the BulkLoader instance
	lazy.addEventListener(ProgressEvent.PROGRESS, onLazyProgress);
	lazy.addEventListener(Event.LAZY_LOADED, onAllItemsLoaded);

	function onLazyLoaded(evt : Event) : void{
	// now you can add individual events for items
	onLazyLoaded.get("config").addEventListener(BulkLoader.COMPLETE, onConfigLoaded);
	...
	}
	</listing>
	 */
	dynamic public class LazyXMLLoader extends LazyBulkLoader
	{
		public function LazyXMLLoader(url:*, name:String, numConnections:int=BulkLoader.DEFAULT_NUM_CONNECTIONS)
		{
			super(url, name, numConnections);
		}
		public var _sourceXML:XML;

		/** Reads a xml as a string and create a complete bulk loader from it.
		 *   @param withData The xml to be read as a string.
		 *   @private
		 */
		lazy_loader override function _lazyParseLoader(withData:String):void
		{
			var xml:XML=_sourceXML=new XML(withData);
			var substitutions:Object=stringSubstitutions || {};
			for each (var substitutionXML:* in xml.stringSubstitutions.children())
			{
				substitutions[substitutionXML.name()]=substitutionXML.toString();
			}
			stringSubstitutions=substitutions;
			allowsAutoIDFromFileName=lazy_loader::toBoolean(xml.allowsAutoIDFromFileName);
			var possibleHandlerName:String;
			var theNode:XMLList;
			var hasNode:Boolean;
			for each (var itemNode:XML in xml.files.children())
			{
				var props:Object={};
				var atts:XMLList=itemNode.@*;
				var nodeName:String;
				var headers:Array;
				var header:URLRequestHeader;
				var headerName:String;
				var headerValue:String;
				if (!String(itemNode.url))
				{
					trace("[LazyBulkLoader] got a item files with no url, ignoring");
					continue;
				}
				for each (var configNode:XML in itemNode.children())
				{
					nodeName=configNode.name();
					if (nodeName == "headers")
					{
						headers=[];
						for each (var headerNode:XML in configNode.children())
						{
							headerName=String(headerNode.name());
							headerValue=String(headerNode[0]);
							header=new URLRequestHeader(headerName, headerValue);
							headers.push(header);
						}
						props["headers"]=headers;
					}
					else if (nodeName == "context")
					{
						// todo: catch for sound items
						var context:Object;
						if (BulkLoader.guessType(String(itemNode.url)) == BulkLoader.TYPE_SOUND)
						{
							context=new SoundLoaderContext();
						}
						else
						{
							context=new LoaderContext();
						}
						context.applicationDomain=ApplicationDomain.currentDomain;
						props[BulkLoader.CONTEXT]=context;

					}
					else if (lazy_loader::INT_TYPES.indexOf(nodeName) > -1)
					{
						props[nodeName]=int(String(configNode));
							//trace("(is int)");
					}
					else if (lazy_loader::NUMBER_TYPES.indexOf(nodeName) > -1)
					{
						props[nodeName]=Number(String(configNode));
							//trace("(is number)");
					}
					else if (lazy_loader::STRINGED_BOOLEAN.indexOf(nodeName) > -1)
					{
						props[nodeName]=lazy_loader::toBoolean(String(configNode));
							//trace("(is boolean)");
					}
					else if (nodeName != "url")
					{
						props[nodeName]=String(configNode);
					}
				}
				var theItem:LoadingItem=add(String(String(itemNode.url)), props);
			}
		}
	}
}