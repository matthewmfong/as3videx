/*
Feathers
Copyright 2012-2017 Bowler Hat LLC. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.data
{
	import feathers.events.CollectionEventType;
	import feathers.utils.xml.xmlListInsertAt;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	[Exclude(name="data",kind="property")]

	/**
	 * Dispatched when the underlying data source changes and components will
	 * need to redraw the data.
	 *
	 * <p>The properties of the event object have the following values:</p>
	 * <table class="innertable">
	 * <tr><th>Property</th><th>Value</th></tr>
	 * <tr><td><code>bubbles</code></td><td>false</td></tr>
	 * <tr><td><code>currentTarget</code></td><td>The Object that defines the
	 *   event listener that handles the event. For example, if you use
	 *   <code>myButton.addEventListener()</code> to register an event listener,
	 *   myButton is the value of the <code>currentTarget</code>.</td></tr>
	 * <tr><td><code>data</code></td><td>null</td></tr>
	 * <tr><td><code>target</code></td><td>The Object that dispatched the event;
	 *   it is not always the Object listening for the event. Use the
	 *   <code>currentTarget</code> property to always access the Object
	 *   listening for the event.</td></tr>
	 * </table>
	 *
	 * @eventType starling.events.Event.CHANGE
	 */
	[Event(name="change",type="starling.events.Event")]

	/**
	 * Dispatched when the collection has changed drastically, such as when
	 * the underlying data source is replaced completely.
	 *
	 * <p>The properties of the event object have the following values:</p>
	 * <table class="innertable">
	 * <tr><th>Property</th><th>Value</th></tr>
	 * <tr><td><code>bubbles</code></td><td>false</td></tr>
	 * <tr><td><code>currentTarget</code></td><td>The Object that defines the
	 *   event listener that handles the event. For example, if you use
	 *   <code>myButton.addEventListener()</code> to register an event listener,
	 *   myButton is the value of the <code>currentTarget</code>.</td></tr>
	 * <tr><td><code>data</code></td><td>null</td></tr>
	 * <tr><td><code>target</code></td><td>The Object that dispatched the event;
	 *   it is not always the Object listening for the event. Use the
	 *   <code>currentTarget</code> property to always access the Object
	 *   listening for the event.</td></tr>
	 * </table>
	 *
	 * @eventType feathers.events.CollectionEventType.RESET
	 */
	[Event(name="reset",type="starling.events.Event")]

	/**
	 * Dispatched when an item is added to the collection.
	 *
	 * <p>The properties of the event object have the following values:</p>
	 * <table class="innertable">
	 * <tr><th>Property</th><th>Value</th></tr>
	 * <tr><td><code>bubbles</code></td><td>false</td></tr>
	 * <tr><td><code>currentTarget</code></td><td>The Object that defines the
	 *   event listener that handles the event. For example, if you use
	 *   <code>myButton.addEventListener()</code> to register an event listener,
	 *   myButton is the value of the <code>currentTarget</code>.</td></tr>
	 * <tr><td><code>data</code></td><td>The index of the item that has been
	 * added. It is of type <code>int</code>.</td></tr>
	 * <tr><td><code>target</code></td><td>The Object that dispatched the event;
	 *   it is not always the Object listening for the event. Use the
	 *   <code>currentTarget</code> property to always access the Object
	 *   listening for the event.</td></tr>
	 * </table>
	 *
	 * @eventType feathers.events.CollectionEventType.ADD_ITEM
	 */
	[Event(name="addItem",type="starling.events.Event")]

	/**
	 * Dispatched when an item is removed from the collection.
	 *
	 * <p>The properties of the event object have the following values:</p>
	 * <table class="innertable">
	 * <tr><th>Property</th><th>Value</th></tr>
	 * <tr><td><code>bubbles</code></td><td>false</td></tr>
	 * <tr><td><code>currentTarget</code></td><td>The Object that defines the
	 *   event listener that handles the event. For example, if you use
	 *   <code>myButton.addEventListener()</code> to register an event listener,
	 *   myButton is the value of the <code>currentTarget</code>.</td></tr>
	 * <tr><td><code>data</code></td><td>The index of the item that has been
	 * removed. It is of type <code>int</code>.</td></tr>
	 * <tr><td><code>target</code></td><td>The Object that dispatched the event;
	 *   it is not always the Object listening for the event. Use the
	 *   <code>currentTarget</code> property to always access the Object
	 *   listening for the event.</td></tr>
	 * </table>
	 *
	 * @eventType feathers.events.CollectionEventType.REMOVE_ITEM
	 */
	[Event(name="removeItem",type="starling.events.Event")]

	/**
	 * Dispatched when an item is replaced in the collection.
	 *
	 * <p>The properties of the event object have the following values:</p>
	 * <table class="innertable">
	 * <tr><th>Property</th><th>Value</th></tr>
	 * <tr><td><code>bubbles</code></td><td>false</td></tr>
	 * <tr><td><code>currentTarget</code></td><td>The Object that defines the
	 *   event listener that handles the event. For example, if you use
	 *   <code>myButton.addEventListener()</code> to register an event listener,
	 *   myButton is the value of the <code>currentTarget</code>.</td></tr>
	 * <tr><td><code>data</code></td><td>The index of the item that has been
	 * replaced. It is of type <code>int</code>.</td></tr>
	 * <tr><td><code>target</code></td><td>The Object that dispatched the event;
	 *   it is not always the Object listening for the event. Use the
	 *   <code>currentTarget</code> property to always access the Object
	 *   listening for the event.</td></tr>
	 * </table>
	 *
	 * @eventType feathers.events.CollectionEventType.REPLACE_ITEM
	 */
	[Event(name="replaceItem",type="starling.events.Event")]

	/**
	 * Dispatched when the <code>updateItemAt()</code> function is called on the
	 * <code>ListCollection</code>.
	 *
	 * <p>The properties of the event object have the following values:</p>
	 * <table class="innertable">
	 * <tr><th>Property</th><th>Value</th></tr>
	 * <tr><td><code>bubbles</code></td><td>false</td></tr>
	 * <tr><td><code>currentTarget</code></td><td>The Object that defines the
	 *   event listener that handles the event. For example, if you use
	 *   <code>myButton.addEventListener()</code> to register an event listener,
	 *   myButton is the value of the <code>currentTarget</code>.</td></tr>
	 * <tr><td><code>data</code></td><td>The index of the item that has been
	 * updated. It is of type <code>int</code>.</td></tr>
	 * <tr><td><code>target</code></td><td>The Object that dispatched the event;
	 *   it is not always the Object listening for the event. Use the
	 *   <code>currentTarget</code> property to always access the Object
	 *   listening for the event.</td></tr>
	 * </table>
	 *
	 * @see #updateItemAt()
	 *
	 * @eventType feathers.events.CollectionEventType.UPDATE_ITEM
	 */
	[Event(name="updateItem",type="starling.events.Event")]

	/**
	 * Dispatched when the <code>updateAll()</code> function is called on the
	 * <code>ListCollection</code>.
	 *
	 * <p>The properties of the event object have the following values:</p>
	 * <table class="innertable">
	 * <tr><th>Property</th><th>Value</th></tr>
	 * <tr><td><code>bubbles</code></td><td>false</td></tr>
	 * <tr><td><code>currentTarget</code></td><td>The Object that defines the
	 *   event listener that handles the event. For example, if you use
	 *   <code>myButton.addEventListener()</code> to register an event listener,
	 *   myButton is the value of the <code>currentTarget</code>.</td></tr>
	 * <tr><td><code>data</code></td><td>null</td></tr>
	 * <tr><td><code>target</code></td><td>The Object that dispatched the event;
	 *   it is not always the Object listening for the event. Use the
	 *   <code>currentTarget</code> property to always access the Object
	 *   listening for the event.</td></tr>
	 * </table>
	 *
	 * @see #updateAll()
	 *
	 * @eventType feathers.events.CollectionEventType.UPDATE_ALL
	 */
	[Event(name="updateAll",type="starling.events.Event")]

	/**
	 * Wraps an <code>XMLList</code> in the common <code>IListCollection</code>
	 * API used by many Feathers UI controls, including <code>List</code> and
	 * <code>TabBar</code>.
	 * 
	 * @productversion Feathers 3.3.0
	 */
	public class XMLListCollection extends EventDispatcher implements IListCollection
	{
		/**
		 * Constructor.
		 */
		public function XMLListCollection(data:XMLList = null)
		{
			if(xmlListData === null)
			{
				xmlListData = new XMLList();
			}
			this._xmlListData = data;
		}

		/**
		 * @private
		 */
		protected var _filteredData:Array;

		/**
		 * @private
		 */
		protected var _xmlListData:XMLList;

		/**
		 * The <code>XMLList</code> data source for this collection. 
		 */
		public function get xmlListData():XMLList
		{
			return this._xmlListData;
		}

		/**
		 * @private
		 */
		public function set xmlListData(value:XMLList):void
		{
			if(this._xmlListData === value)
			{
				return;
			}
			this._xmlListData = value;
			this.dispatchEventWith(CollectionEventType.RESET);
			this.dispatchEventWith(Event.CHANGE);
		}

		[Deprecated(replacement="xmlListData",since="3.3.0")]
		/**
		 * @private
		 */
		public function get data():Object
		{
			return this.xmlListData;
		}

		[Deprecated(replacement="xmlListData",since="3.3.0")]
		/**
		 * @private
		 */
		public function set data(value:Object):void
		{
			if(!(value is XMLList))
			{
				throw new ArgumentError("XMLListCollection data must be of type XMLList.");
			}
			this.xmlListData = value as XMLList;
		}

		/**
		 * @private
		 */
		protected var _pendingRefresh:Boolean = false;

		/**
		 * @private
		 */
		protected var _filterFunction:Function;

		/**
		 * @copy feathers.data.IListCollection#filterFunction
		 */
		public function get filterFunction():Function
		{
			return this._filterFunction;
		}

		/**
		 * @private
		 */
		public function set filterFunction(value:Function):void
		{
			if(this._filterFunction === value)
			{
				return;
			}
			this._filterFunction = value;
			this._pendingRefresh = true;
			this.dispatchEventWith(Event.CHANGE);
			this.dispatchEventWith(CollectionEventType.FILTER_CHANGE);
		}

		/**
		 * @copy feathers.data.IListCollection#length
		 */
		public function get length():int
		{
			if(this._pendingRefresh)
			{
				this.refresh();
			}
			if(this._filteredData !== null)
			{
				return this._filteredData.length;
			}
			return this._xmlListData.length();
		}

		/**
		 * @copy feathers.data.IListCollection#refreshFilter()
		 */
		public function refreshFilter():void
		{
			if(this._filterFunction === null)
			{
				return;
			}
			this._pendingRefresh = true;
			this.dispatchEventWith(Event.CHANGE);
			this.dispatchEventWith(CollectionEventType.FILTER_CHANGE);
		}

		/**
		 * @private
		 */
		protected function refresh():void
		{
			this._pendingRefresh = false;
			if(this._filterFunction !== null)
			{
				var result:Array = this._filteredData;
				if(result !== null)
				{
					//reuse the old array to avoid garbage collection
					result.length = 0;
				}
				else
				{
					result = [];
				}
				var itemCount:int = this._xmlListData.length();
				var pushIndex:int = 0;
				for(var i:int = 0; i < itemCount; i++)
				{
					var item:XML = this._xmlListData[i];
					if(this._filterFunction(item))
					{
						result[pushIndex] = item;
						pushIndex++;
					}
				}
				this._filteredData = result;
			}
			else
			{
				this._filteredData = null;
			}
		}

		/**
		 * @copy feathers.data.IListCollection#updateItemAt()
		 *
		 * @see #updateAll()
		 */
		public function updateItemAt(index:int):void
		{
			this.dispatchEventWith(CollectionEventType.UPDATE_ITEM, false, index);
		}

		/**
		 * @copy feathers.data.IListCollection#updateAll()
		 *
		 * @see #updateItemAt()
		 */
		public function updateAll():void
		{
			this.dispatchEventWith(CollectionEventType.UPDATE_ALL);
		}

		/**
		 * @copy feathers.data.IListCollection#getItemAt()
		 */
		public function getItemAt(index:int):Object
		{
			if(this._pendingRefresh)
			{
				this.refresh();
			}
			if(this._filteredData !== null)
			{
				return this._filteredData[index];
			}
			return this._xmlListData[index];
		}

		/**
		 * @copy feathers.data.IListCollection#getItemIndex()
		 */
		public function getItemIndex(item:Object):int
		{
			if(this._pendingRefresh)
			{
				this.refresh();
			}
			if(this._filteredData !== null)
			{
				return this._filteredData.indexOf(item);
			}
			return this.xmlListIndexOf(item);
		}

		/**
		 * @copy feathers.data.IListCollection#addItemAt()
		 */
		public function addItemAt(item:Object, index:int):void
		{
			if(this._pendingRefresh)
			{
				this.refresh();
			}
			if(this._filteredData !== null)
			{
				if(index < this._filteredData.length)
				{
					//find the item at the index in the filtered data, and use
					//its index from the unfiltered data
					var oldItem:Object = this._filteredData[index];
					var unfilteredIndex:int = this.xmlListIndexOf(oldItem);
				}
				else
				{
					//if the item is added at the end of the filtered data
					//then add it at the end of the unfiltered data
					unfilteredIndex = this._xmlListData.length();
				}
				//always add to the original data
				this._xmlListData = xmlListInsertAt(this._xmlListData, unfilteredIndex, item as XML);
				//but check if the item should be in the filtered data
				var includeItem:Boolean = true;
				if(this._filterFunction !== null)
				{
					includeItem = this._filterFunction(item);
				}
				if(includeItem)
				{
					this._filteredData.insertAt(index, item);
					//don't dispatch these events if the item is filtered!
					this.dispatchEventWith(Event.CHANGE);
					this.dispatchEventWith(CollectionEventType.ADD_ITEM, false, index);
				}
			}
			else
			{
				this._xmlListData = xmlListInsertAt(this._xmlListData, index, item as XML);
				this.dispatchEventWith(Event.CHANGE);
				this.dispatchEventWith(CollectionEventType.ADD_ITEM, false, index);
			}
		}

		/**
		 * @copy feathers.data.IListCollection#removeItemAt()
		 */
		public function removeItemAt(index:int):Object
		{
			if(this._pendingRefresh)
			{
				this.refresh();
			}
			if(this._filteredData !== null)
			{
				var item:Object = this._filteredData.removeAt(index);
				var unfilteredIndex:int = this.xmlListIndexOf(item);
				delete this._xmlListData[unfilteredIndex];
			}
			else
			{
				item = this._xmlListData[index];
				delete this._xmlListData[index];
			}
			this.dispatchEventWith(Event.CHANGE);
			this.dispatchEventWith(CollectionEventType.REMOVE_ITEM, false, index);
			return item;
		}

		/**
		 * @copy feathers.data.IListCollection#removeItem()
		 */
		public function removeItem(item:Object):void
		{
			var index:int = this.getItemIndex(item);
			if(index >= 0)
			{
				this.removeItemAt(index);
			}
		}

		/**
		 * @copy feathers.data.IListCollection#removeAll()
		 */
		public function removeAll():void
		{
			if(this._pendingRefresh)
			{
				this.refresh();
			}
			if(this.length === 0)
			{
				return;
			}
			if(this._filteredData !== null)
			{
				this._filteredData.length = 0;
			}
			else
			{
				this.xmlListDeleteAll();
			}
			this.dispatchEventWith(CollectionEventType.REMOVE_ALL);
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @copy feathers.data.IListCollection#setItemAt()
		 */
		public function setItemAt(item:Object, index:int):void
		{
			if(this._pendingRefresh)
			{
				this.refresh();
			}
			if(this._filteredData !== null)
			{
				var oldItem:Object = this._filteredData[index];
				var unfilteredIndex:int = this.xmlListIndexOf(oldItem);
				this._xmlListData[unfilteredIndex] = item;
				if(this._filterFunction !== null)
				{
					var includeItem:Boolean = this._filterFunction(item);
					if(includeItem)
					{
						this._filteredData[index] = item;
						this.dispatchEventWith(Event.CHANGE);
						this.dispatchEventWith(CollectionEventType.REPLACE_ITEM, false, index);
						return;
					}
					else
					{
						//if the item is excluded, the item at this index is
						//removed instead of being replaced by the new item
						this._filteredData.removeAt(index);
						this.dispatchEventWith(Event.CHANGE);
						this.dispatchEventWith(CollectionEventType.REMOVE_ITEM, false, index);
					}
				}
			}
			else
			{
				this._xmlListData[index] = item;
				this.dispatchEventWith(Event.CHANGE);
				this.dispatchEventWith(CollectionEventType.REPLACE_ITEM, false, index);
			}
		}

		/**
		 * @copy feathers.data.IListCollection#addItem()
		 */
		public function addItem(item:Object):void
		{
			this.addItemAt(item, this.length);
		}

		/**
		 * @copy feathers.data.IListCollection#push()
		 *
		 * @see #addItem()
		 */
		public function push(item:Object):void
		{
			this.addItemAt(item, this.length);
		}

		/**
		 * @copy feathers.data.IListCollection#addAll()
		 */
		public function addAll(collection:IListCollection):void
		{
			var otherCollectionLength:int = collection.length;
			var pushIndex:int = this._xmlListData.length();
			for(var i:int = 0; i < otherCollectionLength; i++)
			{
				var item:Object = collection.getItemAt(i);
				this._xmlListData[pushIndex] = item;
				pushIndex++;
			}
		}

		/**
		 * @copy feathers.data.IListCollection#addAllAt()
		 */
		public function addAllAt(collection:IListCollection, index:int):void
		{
			var otherCollectionLength:int = collection.length;
			var currentIndex:int = index;
			for(var i:int = 0; i < otherCollectionLength; i++)
			{
				var item:Object = collection.getItemAt(i);
				this._xmlListData = xmlListInsertAt(this._xmlListData, currentIndex, item as XML);
				currentIndex++;
			}
		}

		/**
		 * @copy feathers.data.IListCollection#reset()
		 */
		public function reset(collection:IListCollection):void
		{
			this.xmlListDeleteAll();
			var otherCollectionLength:int = collection.length;
			for(var i:int = 0; i < otherCollectionLength; i++)
			{
				var item:Object = collection.getItemAt(i);
				this._xmlListData[i] = item;
			}
			this.dispatchEventWith(CollectionEventType.RESET);
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @copy feathers.data.IListCollection#pop()
		 */
		public function pop():Object
		{
			return this.removeItemAt(this.length - 1);
		}

		/**
		 * @copy feathers.data.IListCollection#unshift()
		 */
		public function unshift(item:Object):void
		{
			this.addItemAt(item, 0);
		}

		/**
		 * @copy feathers.data.IListCollection#shift()
		 */
		public function shift():Object
		{
			return this.removeItemAt(0);
		}

		/**
		 * @copy feathers.data.IListCollection#contains()
		 */
		public function contains(item:Object):Boolean
		{
			return this.xmlListIndexOf(item) !== -1;
		}

		/**
		 * @copy feathers.data.IListCollection#dispose()
		 *
		 * @see http://doc.starling-framework.org/core/starling/display/DisplayObject.html#dispose() starling.display.DisplayObject.dispose()
		 * @see http://doc.starling-framework.org/core/starling/textures/Texture.html#dispose() starling.textures.Texture.dispose()
		 */
		public function dispose(disposeItem:Function):void
		{
			//if we're disposing the collection, filters don't matter anymore,
			//and we should ensure that all items are disposed.
			this._filterFunction = null;
			this.refresh();

			var itemCount:int = this._xmlListData.length();
			for(var i:int = 0; i < itemCount; i++)
			{
				var item:Object = this._xmlListData[i];
				disposeItem(item);
			}
		}

		/**
		 * @private
		 */
		protected function xmlListIndexOf(item:Object):int
		{
			var listLength:int = this._xmlListData.length();
			for(var i:int = 0; i < listLength; i++)
			{
				var currentItem:XML = this._xmlListData[i];
				if(currentItem == item)
				{
					return i;
				}
			}
			return -1;
		}

		/**
		 * @private
		 */
		protected function xmlListDeleteAll():void
		{
			var listLength:int = this._xmlListData.length();
			for(var i:int = 0; i < listLength; i++)
			{
				delete this._xmlListData[0];
			}
		}
	}
}